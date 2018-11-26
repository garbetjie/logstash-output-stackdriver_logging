# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"
require "logstash/logging"
require 'google/apis/logging_v2'
require 'googleauth'
require 'json'
require 'faraday'

# An example output that does nothing.
class LogStash::Outputs::StackdriverLogging < LogStash::Outputs::Base
  config_name "stackdriver_logging"

  # The Google Cloud project to write the logs to. This is optional if running on GCE,
  # and will default to the instance's project.
  config :project_id, :validate => :string, :required => false, :default => nil

  # The path to the service account JSON file that contains the credentials
  # of the service account to write logs as.
  config :key_file, :validate => :path, :required => false

  # The name of the log to write logs to.
  config :log_name, :validate => :string, :required => true

  # The field name in the event that references the log level to use.
  config :severity_field, :validate => :string, :required => false, :default => "severity"

  # The field name in the event that contains the timestamp of the log message.
  config :timestamp_field, :validate => :string, :required => false, :default => "@timestamp"

  # If no severity is found, the default severity level to assume.
  config :default_severity, :validate => :string, :required => false, :default => "default"

  # Boolean flag indicating whether or not to remove the fields in the event that are prefixed with "@".
  config :strip_at_fields, :validate => :boolean, :required => false, :default => false

  # Array of fields to strip out before sending.
  config :strip_fields, :validate => :array, :required => false, :default => []

  concurrency :single

  public
  def register
    @service = Google::Apis::LoggingV2::LoggingService.new
    scope = %w(https://www.googleapis.com/auth/logging.write)

    # Always load key file if provided.
    if @key_file
      @service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(json_key_io: File.open(@key_file),
                                                                                  scope: scope)
    # Fall back to getting the application default credentials.
    else
      @service.authorization = Google::Auth.get_application_default(scope)
    end

    # project_id is not defined. Try to extract it from teh metadata server.
    unless @project_id
      if Google::Auth::GCECredentials.on_gce?
        connection = Faraday::Connection.new("http://169.254.169.254/computeMetadata/v1/", { :headers => headers })
        connection.headers = { "Metadata-Flavor": "Google" }
        response = connection.get "project/project-id"

        if response.status
          @project_id = response.body.to_s.strip
        end


      else
        @logger.error "Unable to detect the Google Cloud project ID to which logs should be written." \
                      "Please ensure that you specify the `project_id` config parameter if not running on the Google " \
                      "Cloud Platform."
        @logger.error "You will not be able to be able to write logs to Google Cloud until this is resolved."
      end
    end
  end

  public
  # @param [Array] events
  def multi_receive(events)
    # Do nothing if no events are received.
    if events.length < 1
      return
    end

    entries = []

    events.each do |event|
      entry = Google::Apis::LoggingV2::LogEntry.new
      entry.severity = event.include?(@severity_field) ? event.get(@severity_field) : @default_severity
      entry.log_name = "projects/%{project}/logs/%{log_name}" % { :project => @project_id, :log_name => event.sprintf(@log_name) }
      entry.timestamp = event.get(@timestamp_field)
      entry.json_payload = event.to_hash

      # Strip the "@" fields.
      if @strip_at_fields or @strip_fields.length > 0
        filtered = {}

        entry.json_payload.each do |key, value|
          if @strip_at_fields && key[0] == "@"
            next
          end

          if @strip_fields.length > 0 && @strip_fields.include?(key)
            next
          end

          filtered[key] = value
        end

        entry.json_payload = filtered
      end

      entries.push entry
    end

    resource = Google::Apis::LoggingV2::MonitoredResource.new
    resource.type = "global"
    resource.labels = { :project_id => @project_id }

    request = Google::Apis::LoggingV2::WriteLogEntriesRequest.new(entries: entries)
    request.resource = resource

    @service.write_entry_log_entries(request) do |result, error|
      if error
        @logger.error "Unable to write log entries to Stackdriver Logging."
        @logger.error "Received this error: " + error.to_s
      else
        @logger.debug("Wrote %{length} entries successfully." % { :length => entries.length })
      end
    end
  end
end
