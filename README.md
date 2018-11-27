# Stackdriver Logging Logstash Plugin

This is a plugin for [Logstash](https://github.com/elastic/logstash).

It is fully free and fully open source. The license is MIT, meaning you are pretty much free to use it however you want in whatever way.


## Summary

This plugin sends events to Stackdriver Logging. Events are sent in batches as they are received.


## Usage

This is an example of Logstash config for this plugin:

```
output {
    stackdriver_logging {
        project_id => "folkloric-guru-278"    (optional) <1>
        key_file => "/path/to/key_file.json"  (optional) <2>
        log_name => ""                        (required) <3>
        severity_field => "severity"          (optional)
        timestamp_field => "@timestamp"       (optional)
        default_severity => "default"         (optional)
        strip_at_fields => false              (optional)
        strip_fields => []                    (optional)
    }
}
```

There are some points to keep in mind when providing configuration:

1. When running on Google Compute Engine and no `project_id` is provided, the `project_id` paramater will be
   automatically retrieved from the metadata server.

2. If no key is provided, defaults to using [Application Default Credentials](https://cloud.google.com/docs/authentication/production).

3. The log name can be interpolated with event fields, to extract the log name from a message (ie: `log_name => "%{[log_name]}"`).

## Considerations

There is a cost to storing log data in Stackdriver Logging. See [the pricing guide](https://cloud.google.com/stackdriver/pricing)
for more information on costs involved.

All logs are stored under the `global` resource.