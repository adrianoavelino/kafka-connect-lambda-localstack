# kafka-connect-lambda-localstack
[![build-test](https://github.com/adrianoavelino/kafka-connect-lambda-localstack/actions/workflows/build-test.yml/badge.svg)](https://github.com/adrianoavelino/kafka-connect-lambda-localstack/actions/workflows/build-test.yml)
![GitHub top language](https://img.shields.io/github/languages/top/adrianoavelino/kafka-connect-lambda-localstack)
[![Repository size](https://img.shields.io/github/repo-size/adrianoavelino/kafka-connect-lambda-localstack)](https://img.shields.io/github/repo-size/adrianoavelino/kafka-connect-lambda-localstack)
[![Last commit](https://img.shields.io/github/last-commit/adrianoavelino/kafka-connect-lambda-localstack)](https://github.com/adrianoavelino/kafka-connect-lambda-localstack/commits/master)


A Kafka Connect sink plugin to invoke Lambda functions in AWS or Localstack.

## Compatibility Matrix
|kafka-connect-lambda|Kafka Connect API|AWS SDK|
|:---|:---|:---|
|1.1.0|2.2.0|1.11.592|
|1.1.1|2.2.0|1.11.592|
|1.2.0|2.3.0|1.11.651|
|1.3.0|2.8.1|1.11.1034|

Due to a compatibility issue with [Apache httpcomponents](http://hc.apache.org/), connector versions 1.1.1 and earlier may not work with Kafka Connect versions greater than 2.2

# Building

Build the connector with Maven using the standard lifecycle goals:

```bash
mvn clean
mvn package
```

# Configuring

In addition to the standard [Kafka Connect connector configuration](https://kafka.apache.org/documentation/#connect_configuring) properties, the `kafka-connect-lambda` properties available are:

| Property | Required | Default value | Description |
|:---------|:---------|:--------|:------------|
| `aws.credentials.provider.class` | No | [Default AWS provider chain](https://docs.aws.amazon.com/AWSJavaSDK/latest/javadoc/com/amazonaws/auth/DefaultAWSCredentialsProviderChain.html) | Class name of an `AWSCredentialsProvider` implementation |
| `aws.lambda.function.arn` | Yes | | Full ARN of the Lambda function |
| `aws.lambda.invocation.timeout.ms` | No | `300000` | Time to wait for a lambda invocation before continuing |
| `aws.lambda.invocation.mode` | No | `SYNC` | `SYNC` for a synchronous invocation; otherwise `ASYNC` |
| `aws.lambda.invocation.failure.mode` | No | `STOP` | Whether to `STOP` processing, or `DROP` and continue after an invocation failure |
| `aws.lambda.batch.enabled` | No | `true` | `true` to batch messages together before an invocation; otherwise `false` |
| `aws.region` | Yes | | AWS region of the Lambda function |
| `http.proxy.host` | No | | HTTP proxy host name |
| `http.proxy.port` | No | | HTTP proxy port number |
| `retriable.error.codes` | No | `500,503,504` | HTTP status codes that will trigger an invocation retry |
| `retry.backoff.millis` | No | `500` | Time to append between invocation retries |
| `retries.max` | No | `5` | Maximum number of invocation retries |
| `topics` | Yes | | Comma-delimited Kafka topics names to sink |
| `payload.formatter.class` | No | `com.nordstrom.kafka.connect.formatters.PlainPayloadFormatter` | Specifies the formatter to use. |
| `payload.formatter.key.schema.visibility` | No | `min` | Determines whether schema (if present) is included. Only applies to JsonPayloadFormatter |
| `payload.formatter.value.schema.visibility` | No | `min` | Determines whether schema (if present) is included. Only applies to JsonPayloadFormatter |
| `localstack.enabled` | No | `false` | Determines whether to use Localstack for development on localhost. |
| `endpoint.url.localstack` | No | `http://localhost:4566` | Determines the endpoint URL for Localstack. |

## Formatters

The connector includes two `payload.formatter.class` implementations:

  * `com.nordstrom.kafka.connect.formatters.PlainPayloadFormatter`
  * `com.nordstrom.kafka.connect.formatters.JsonPayloadFormatter`

Including the full schema information in the invocation payload may result in very large messages. Therefore, use the `schema.visibility` key and value properties to control how much of the schema, if present, to include in the invocation payload: `none`, `min`, or `all` (default=`min`). These settings apply to the `JsonPayloadFormatter` only; The `PlainPayloadFormatter` always includes the `min` schema information.


## Configuration Examples
An example configuration represented as JSON data for use with the [Kafka Connect REST interface](https://docs.confluent.io/current/connect/references/restapi.html):

```json
{
  "name": "example-lambda-connector",
  "config": {
    "tasks.max": "1",
    "connector.class": "com.nordstrom.kafka.connect.lambda.LambdaSinkConnector",
    "topics": "<Your Kafka topics>",
    "key.converter": "org.apache.kafka.connect.storage.StringConverter",
    "value.converter": "org.apache.kafka.connect.storage.StringConverter",
    "aws.region": "<Your AWS region>",
    "aws.lambda.function.arn": "<Your function ARN>",
    "aws.lambda.batch.enabled": "false"
  }
}
```

## IAM assume-role options

By supplying `com.nordstrom.kafka.connect.auth.AWSAssumeRoleCredentialsProvider` as the `aws.credentials.provider.class` configuration, the connector can assume an IAM Role. The role must include a policy that allows `lambda:InvokeFunction` and `lambda:InvokeAsync` actions.

| Property | Required | Description |
|:---------|:---------|:------------|
| `aws.credentials.provider.role.arn` | Yes | Full ARN of the IAM Role to assume |
| `aws.credentials.provider.session.name` | Yes | Name that uniquely identifies a session while the role is being assumed |
| `aws.credentials.provider.external.id` | No | External identifier used by the `kafka-connect-lambda` when assuming the role |

# Invocation payloads

The default invocation payload is a JSON representation of a [SinkRecord](https://kafka.apache.org/21/javadoc/org/apache/kafka/connect/sink/SinkRecord.html) object, which contains the Kafka message in the `value` field. When `aws.lambda.batch.enabled` is `true`, the invocation payload is an array of these records.

## Avro schema

This simple schema record describes our "hello, world" message.


```json
{
  "type": "record",
  "name": "Hello",
  "doc": "An example Avro-encoded `Hello` message.",
  "namespace": "com.nordstrom.kafka.example",
  "fields": [
    {
      "name": "language",
      "type": {
        "type": "enum",
        "name": "language",
        "symbols": [ "ENGLISH", "FRENCH", "ITALIAN", "SPANISH"
        ]
      }
    },
    {
      "name": "greeting",
      "type": "string"
    }
  ]
}

```

### PlainPayloadFormatter

This example uses the following (partial) connector configuration which defaults to `payload.formatter=com.nordstrom.kafka.connect.formatters.PlainPayloadFormatter`:

```json
key.converter=org.apache.kafka.connect.storage.StringConverter
value.converter=io.confluent.connect.avro.AvroConverter
aws.lambda.batch.enabled=false
```

Expected output:


```json
{
    "key": "my_key",
    "keySchemaName": null,
    "value": "Struct{language=ENGLISH,greeting=hello, world}",
    "valueSchemaName": "com.nordstrom.kafka.example.Hello",
    "topic": "example-stream",
    "partition": 1,
    "offset": 0,
    "timestamp": 1567723257583,
    "timestampTypeName": "CreateTime"
}
```

### JsonPayloadFormatter

This example uses the following (partial) connector configuration with key and value schema visibility as `min` (the default):

```json
key.converter=org.apache.kafka.connect.storage.StringConverter
value.converter=io.confluent.connect.avro.AvroConverter
aws.lambda.batch.enabled=false
payload.formatter.class=com.nordstrom.kafka.connect.formatters.JsonPayloadFormatter
```

Expected output:

```json
{
    "key": "my_key",
    "keySchemaName": null,
    "keySchemaVersion": null,
    "value": {
        "language": "ENGLISH",
        "greeting": "hello, world"
    },
    "valueSchemaName": "com.nordstrom.kafka.example.Hello",
    "valueSchemaVersion": "1",
    "topic": "example-stream",
    "partition": 1,
    "offset": 0,
    "timestamp": 1567723257583,
    "timestampTypeName": "CreateTime"
}
```

# Try the example demo

Follow the demo in order to: create an AWS Lambda function, build the connector plugin, run the connector, and send a message.

## Build the connector plugin

```bash
mvn clean package
```

Once built, a `kafka-connect-lambda` uber-jar is in the `target/plugin` directory.

## Starts Kafka containers / Localstack
```bash
docker-compose up
```

## Create an AWS Lambda function

With an active AWS account, can create a simple AWS Lambda function using the [CloudFormation](https://aws.amazon.com/cloudformation) template in the `config/` directory:

Example using AWS:
```bash
aws cloudformation create-stack \
  --stack-name example-lambda-stack \
  --capabilities CAPABILITY_NAMED_IAM \
  --template-body file://config/cloudformation.yml
```

Example using Localstack:
> Note: Before running the commands, ensure you set the default profile for LocalStack by using aws configure --profile default.
```bash
aws cloudformation create-stack \
  --stack-name example-lambda-stack \
  --capabilities CAPABILITY_NAMED_IAM \
  --template-body file://config/cloudformation.yml \
  --endpoint-url http://localhost:4566
```

To make sure our Lambda works, invoke it directly and view the result payload in `result.txt`:

Example using AWS:
```bash
aws lambda invoke --function-name example-function \
--cli-binary-format raw-in-base64-out \
--payload '{"value": "my example"}' --output text result.txt
```

Example using Localstack:
```bash
aws lambda invoke --function-name example-function \
--cli-binary-format raw-in-base64-out \
--payload '{"value": "my example"}' --output text result.txt \
--endpoint-url http://localhost:4566
```

The function simply sends the `payload` back to you in `result.txt` as serialized json.

Use the `describe-stacks` command to fetch the CloudFormation output value for `ExampleFunctionArn`, which we'll need later when setting up our connector configuration:

```bash
aws cloudformation describe-stacks \
--stack-name example-lambda-stack \
--query "Stacks[0].Outputs[]"
```

```bash
aws cloudformation describe-stacks \
--stack-name example-lambda-stack \
--query "Stacks[0].Outputs[]" \
--endpoint-url http://localhost:4566
```

## Run the connector using Docker Compose

Ensure you have `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables exported in your shell. Docker Compose will pass these values into the `connect` container.

Use the provided [Docker Compose](https://docs.docker.com/compose) file and run `docker-compose up`.

With the [Kafka Connect REST interface](https://docs.confluent.io/current/connect/references/restapi.html), verify the Lambda sink connector is installed and ready: `curl http://localhost:8083/connector-plugins`.

Next, supply a connector configuration. You can use `config/connector.json.example` as a starting-point. Fill in values for `<Your AWS Region>` and `<Your function ARN>` and run:

### AWS Lambda
To create the connector for a lambda in AWS, use the following command:
```bash
curl -XPOST -H 'Content-Type: application/json' http://localhost:8083/connectors \
-d @config/connector.json
```

To show the status of the connector for a lambda in AWS, use the following command:
```bash
curl http://localhost:8083/connectors/example-lambda-connector/status
```

### LocalStack lambda
In Localstack with string converter, use the command below:
```bash
curl -XPOST -H 'Content-Type: application/json' http://localhost:8083/connectors \
-d @config/connector-localstack.json
```
Shows the status of the connector:
```bash
curl http://localhost:8083/connectors/example-lambda-connector-localstack/status
```

To create the connector using Localstack with the Avro converter, follow this step:
```bash
curl -XPOST -H 'Content-Type: application/json' http://localhost:8083/connectors -d @config/connector-localstack-avro.json
```

Shows the status of connector
```bash
curl http://localhost:8083/connectors/example-lambda-connector-localstack-avro/status
```

## Run the connector using the Confluent Platform

Run the ZooKeeper and Kafka components from the [Confluent Platform](https://www.confluent.io/download).

Next, configure a Java properties-file containing your connector configuration. You can use `config/connector.properties.example` as a starting-point. Fill in values for `<Your AWS Region>` and `<Your function ARN>`.

Ensure you have `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables exported in your shell. Then, run the connector in "standalone-mode":

```bash
connect-standalone config/worker.properties config/connector.properties
```

## Run the connector using the automation
First, enter in the automation folder and starts the containers. Wait the containers and after that you can see the plugin running:
```bash
# enters the automation folder
cd automation
```
```bash
# starts the containers
docker-compose up -d
```
```bash
# wait for some time for the connector to become ready, then check the status of the connector
curl http://localhost:8083/connectors/example-lambda-connector-localstack/status
```

## Send messages
Using the Kafka console producer, send a message to the `example-stream` topic. Your `example-lambda-connector` will read the message from the topic and invoke the AWS Lambda `example-function`.
With the lambda in AWS Console or in Localstack with string converter use:
```bash
# opens the command line
docker-compose exec broker bash
```
```bash
# connects to the Kafka console producer
kafka-console-producer --broker-list localhost:29092 --topic example-stream
```
To send the messages, paste the messages:
```json
{"value": "my example"}
```
```json
{"value": "my example 2"}
```

With the lambda in LocalStack using avro converter:
Option 1: Continuos messages sending
```bash
# opens the command line
docker-compose exec schema-registry bash
```
```bash
# connects to the Kafka console producer
kafka-avro-console-producer \
--broker-list broker:29092 \
--topic example-stream-avro \
--property key.converter=io.confluent.connect.avro.AvroConverter \
--property value.converter=io.confluent.connect.avro.AvroConverter \
--property value.converter.schema.registry.url=http://schema-registry:8081 \
--property key.converter.schema.registry.url=http://schema-registry:8081 \
--property value.schema='{"type":"record","name":"Hello","doc":"An example Avro-encoded `Hello` message.","namespace":"com.nordstrom.kafka.example","fields":[{"name":"language","type":{"type":"enum","name":"language","symbols":["ENGLISH","FRENCH","ITALIAN","SPANISH"]}},{"name":"greeting","type":"string"}]}' \
--property key.schema='{"type":"record","name":"Header","fields":[{"name":"timestamp","type":"long"}]}' \
--property parse.key=true \
--property key.separator=,
```

To send the messages, paste the messages:
```json
{"timestamp":1637000000000},{"language": "ENGLISH", "greeting": "Hello, World!"}
```
```json
{"timestamp":1637000000000},{"language": "ITALIAN", "greeting": "Ciao, mondo!"}
```

Option 2: Quick single message sending:
```bash
echo "{\"timestamp\":1637000000000},{\"language\": \"ITALIAN\", \"greeting\": \"Ciao, mondo!\"}" | docker compose exec -T schema-registry \
kafka-avro-console-producer \
--broker-list broker:29092 \
--topic example-stream-avro \
--property key.converter=io.confluent.connect.avro.AvroConverter \
--property value.converter=io.confluent.connect.avro.AvroConverter \
--property value.converter.schema.registry.url=http://schema-registry:8081 \
--property key.converter.schema.registry.url=http://schema-registry:8081 \
--property value.schema='{"type":"record","name":"Hello","doc":"An example Avro-encoded `Hello` message.","namespace":"com.nordstrom.kafka.example","fields":[{"name":"language","type":{"type":"enum","name":"language","symbols":["ENGLISH","FRENCH","ITALIAN","SPANISH"]}},{"name":"greeting","type":"string"}]}' \
--property key.schema='{"type":"record","name":"Header","fields":[{"name":"timestamp","type":"long"}]}' \
--property parse.key=true \
--property key.separator=,
```

```bash
echo "{\"timestamp\":1637000000000},{\"language\": \"ENGLISH\", \"greeting\": \"Hello, World!\"}" | docker compose exec -T schema-registry \
kafka-avro-console-producer \
--broker-list broker:29092 \
--topic example-stream-avro \
--property key.converter=io.confluent.connect.avro.AvroConverter \
--property value.converter=io.confluent.connect.avro.AvroConverter \
--property value.converter.schema.registry.url=http://schema-registry:8081 \
--property key.converter.schema.registry.url=http://schema-registry:8081 \
--property value.schema='{"type":"record","name":"Hello","doc":"An example Avro-encoded `Hello` message.","namespace":"com.nordstrom.kafka.example","fields":[{"name":"language","type":{"type":"enum","name":"language","symbols":["ENGLISH","FRENCH","ITALIAN","SPANISH"]}},{"name":"greeting","type":"string"}]}' \
--property key.schema='{"type":"record","name":"Header","fields":[{"name":"timestamp","type":"long"}]}' \
--property parse.key=true \
--property key.separator=,
```

Use the AWS Console to read the output of your message sent from the CloudWatch logs for the Lambda.

In Localstack, use the following commands to display the logs:

AWS CLI 2.0 with bash shell:
```bash
# creates a variable with log group name
LOG_GROUP=`aws logs describe-log-groups \
--endpoint-url http://localhost:4566 \
--query "logGroups[0].logGroupName" | sed 's/"//g'`

# list the logs streams
aws logs tail $LOG_GROUP --follow --endpoint-url http://localhost:4566
```

Or with [fish shell](https://fishshell.com/):
```bash
set LOG_GROUP (aws logs describe-log-groups \
--endpoint-url http://localhost:4566 \
--query "logGroups[0].logGroupName" | sed 's/"//g'; and true)

aws logs tail $LOG_GROUP --follow --endpoint-url http://localhost:4566
```

AWS CLI 1.0:
```bash
# log group name
LOG_GROUP=`aws logs describe-log-groups \
--endpoint-url http://localhost:4566 \
--query "logGroups[0].logGroupName" | sed 's/"//g'`

# log stream name
LOG_STREAM=`aws logs describe-log-streams \
--log-group-name $LOG_GROUP \
--max-items 1 --order-by LastEventTime \
--descending --query logStreams[].logStreamName \
--output text --endpoint-url http://localhost:4566 | head -n 1`

# list the logs streams
aws logs get-log-events --log-group-name $LOG_GROUP \
--log-stream-name $LOG_STREAM \
--query events[].message \
--output text --endpoint-url http://localhost:4566
```

## Delete the connector
To delete the connector with string converter, run:
```bash
curl -XDELETE http://localhost:8083/connectors/example-lambda-connector
```

To delete the connector with string converter in LocalStack, run:
```bash
curl -XDELETE http://localhost:8083/connectors/example-lambda-connector-localstack
```

Or to delete the connector with avro converter in LocalStack, run:
```bash
curl -XDELETE http://localhost:8083/connectors/example-lambda-connector-localstack-avro
```
