input {
	s3 {
		bucket => "${AWS_S3_BUCKET}"
		prefix => "${AWS_S3_PREFIX}"
		region_endpoint => "${AWS_S3_REGION}"
		type => "frontend"
	}
}

filter {
	# Decode CSV
	csv {
		separator => "	"
			columns => [
				"date",
				"time",
				"x-edge-location",
				"sc-bytes",
				"c-ip",
				"cs-method",
				"Host",
				"cs-uri-stem",
				"sc-status",
				"Referer",
				"User-Agent",
				"cs-uri-query",
				"Cookie",
				"x-edge-result-type",
				"x-edge-request-id",
				"x-host-header",
				"cs-protocol",
				"cs-bytes",
				"time-taken",
				"x-forwarded-for",
				"ssl-protocol",
				"ssl-cipher",
				"x-edge-response-result-type"
			]
	}

	mutate {
		remove_field => ["@timestamp"]
	}

	# Take care of dates
	mutate {
		add_field => [ "@timestamp.generated", "%{date} %{time}" ]
	}

	date {
		match => [ "@timestamp.generated", "yy-MM-dd HH:mm:ss" ]
		target => "@timestamp.generated"
		timezone => "UTC"
	}

	ruby {
		code => "event['@timestamp.processed'] = Time.new.to_i"
	}

	date {
		match => [ "@timestamp.processed", "UNIX" ]
		target => "@timestamp.processed"
	}

	# Create a hash w/ the dates
	de_dot {
		fields => ["@timestamp.generated", "@timestamp.processed"]
		nested => true
	}






	# Two pass url decoding ... sigh
	urldecode {
		field => "cs-uri-query"
	}

	urldecode {
		field => "User-Agent"
	}

	# Replace some incompletely decoded html entities
	mutate {
		gsub => [ "User-Agent", "%20", ' ' ]
	}
	mutate {
		gsub => [ "cs-uri-query", "%22", '"' ]
	}
	mutate {
		gsub => [ "cs-uri-query", "%20", ' ' ]
	}
	mutate {
		gsub => [ "cs-uri-query", "%7B", '{' ]
	}
	mutate {
		gsub => [ "cs-uri-query", "%7D", '}' ]
	}
	mutate {
		gsub => [ "cs-uri-query", "%3C", '<' ]
	}
	mutate {
		gsub => [ "cs-uri-query", "%3E", '>' ]
	}
	mutate {
		gsub => [ "cs-uri-query", "%23", "#" ]
	}
	mutate {
		gsub => [ "cs-uri-query", "%25", "%" ]
	}
	mutate {
		gsub => [ "cs-uri-query", "%7C", "|" ]
	}
	mutate {
		gsub => [ "cs-uri-query", "%5C", "\"" ]
	}
	mutate {
		gsub => [ "cs-uri-query", "%5E", "^" ]
	}
	mutate {
		gsub => [ "cs-uri-query", "%7E", "~" ]
	}
	mutate {
		gsub => [ "cs-uri-query", "%5B", "[" ]
	}
	mutate {
		gsub => [ "cs-uri-query", "%5D", "]" ]
	}
	mutate {
		gsub => [ "cs-uri-query", "%60", "`" ]
	}
	mutate {
		gsub => [ "cs-uri-query", "%27", "'" ]
	}

	if ["cs-uri-query" != "-"] {
		json {
			source => "cs-uri-query"
		}
	}


	mutate {
		add_tag => ["not-realtime"]
		add_tag => ["logstash-s3-cloudfront-frontend"]
	}

	geoip {
		source => "c-ip"
		"target" => "client.geoip"
	}
	useragent {
		source => "User-Agent"
		target => "client.agent"
	}

	de_dot {
		fields => ["client.geoip", "client.agent"]
		nested => true
	}
}


output {
	kinesis {
		region => "${AWS_KINESIS_REGION}"
		stream_name => "${AWS_KINESIS_STREAM}"
		aggregation_enabled => false
		randomized_partition_key => true
	}
}
