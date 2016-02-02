input {
	s3 {
		bucket => "${AWS_S3_BUCKET}"
		backup_to_bucket => "${AWS_S3_BUCKET}"
		backup_add_prefix => "Processed/"
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

			add_field => [ "timestamp", "%{date} %{time}" ]
	}

	# Replace: Processed vs Generated timestamp
	date {
		match => [ "timestamp", "yy-MM-dd HH:mm:ss" ]
		timezone => "UTC"
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
