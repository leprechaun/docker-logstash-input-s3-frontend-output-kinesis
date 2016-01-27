# docker-logstash-input-s3-frontend-output-kinesis

** This image is part of a logging framework in development. **

This container will listen on ** s3://$AWS_S3_BUCKET/$AWS_S3_PREFIX ** for coming from
an AWS Cloudfront distribution. With the added bonus of JSON DECODING whatever value is
in `cs-uri-query`.

Why? You ask? Because by doing that, you can very easily push data from any sort of
application (it's an HTTP GET away). Easiest target would be web applications, in a 
google analytics/omniture kind of fashion.

It outputs these events into an AWS Kinesis stream, ready to be picked up by another
processing thing.

## Usage

```
docker run \
 -e AWS_S3_BUCKET=my-cloudfront-logging-bucket
 -e AWS_S3_PREFIX=AWSLogs
 -e AWS_S3_REGION=ap-southeast-2
 -e AWS_KINESIS_REGION=ap-southeast-2
 -e AWS_KINESIS_STREAM=my-output-kinesis-stream
 leprechaun/logstash-input-s3-frontend-output-kinesis
```

All of those environment variables are required. The container will bork if either one is not provided.
