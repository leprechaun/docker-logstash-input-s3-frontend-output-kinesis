#!/usr/bin/env bash

usage () {
	echo "The following environment variables need to be set:"
	echo " - AWS_S3_BUCKET"
	echo " - AWS_S3_PREFIX"
	echo " - AWS_S3_REGION"
	echo " - AWS_KINESIS_REGION"
	echo " - AWS_KINESIS_STREAM"

	echo ""
	echo "Currently missing atleast '$1'"
}

# expecting some ENV vars
[[ -z "$AWS_S3_BUCKET" ]] && usage AWS_S3_BUCKET && exit
[[ -z "$AWS_S3_PREFIX" ]] && usage AWS_S3_PREFIX && exit
[[ -z "$AWS_S3_REGION" ]] && usage AWS_S3_REGION && exit
[[ -z "$AWS_KINESIS_REGION" ]] && usage AWS_KINESIS_REGION && exit
[[ -z "$AWS_KINESIS_STREAM" ]] && usage AWS_KINESIS_STREAM && exit

sed \
	-e "s,\${AWS_S3_BUCKET},${AWS_S3_BUCKET}," \
	-e "s,\${AWS_S3_PREFIX},${AWS_S3_PREFIX}," \
	-e "s,\${AWS_S3_REGION},${AWS_REGION}," \
	-e "s,\${AWS_KINESIS_REGION},${AWS_KINESIS_REGION}," \
	-e "s,\${AWS_KINESIS_STREAM},${AWS_KINESIS_STREAM}," \
	/config/logstash.conf.tpl > /config/logstash.conf

/opt/logstash/bin/logstash -f /config/logstash.conf
