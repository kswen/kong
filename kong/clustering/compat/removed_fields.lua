return {
  -- Any dataplane older than 3.1.0
  [3001000000] = {
    -- OSS
    acme = {
      "enable_ipv4_common_name",
      "storage_config.redis.ssl",
      "storage_config.redis.ssl_verify",
      "storage_config.redis.ssl_server_name",
    },
    rate_limiting = {
      "error_code",
      "error_message",
    },
    response_ratelimiting = {
      "redis_ssl",
      "redis_ssl_verify",
      "redis_server_name",
    },
    datadog = {
      "retry_count",
      "queue_size",
      "flush_timeout",
    },
    statsd = {
      "retry_count",
      "queue_size",
      "flush_timeout",
    },
    session = {
      "cookie_persistent",
    },
    zipkin = {
      "http_response_header_for_traceid",
    },
  },
  -- Any dataplane older than 3.2.0
  [3002000000] = {
    statsd = {
      "tag_style",
    },
    session = {
      "audience",
      "absolute_timeout",
      "remember_cookie_name",
      "remember_rolling_timeout",
      "remember_absolute_timeout",
      "response_headers",
      "request_headers",
    },
    aws_lambda = {
      "aws_imds_protocol_version",
    },
    zipkin = {
      "phase_duration_flavor",
    }
  },
  -- Any dataplane older than 3.3.0
  [3003000000] = {
    acme = {
      "account_key",
    },
    proxy_cache = {
      "ignore_uri_case",
    }
  },
}
