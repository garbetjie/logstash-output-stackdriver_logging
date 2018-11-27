Gem::Specification.new do |s|
  s.name = 'logstash-output-stackdriver_logging'
  s.version = '0.1.1'
  s.licenses = ['MIT']
  s.summary = "Writes payloads to Stackdriver Logging."
  s.description  = ""
  s.authors = ["Geoff Garbers"]
  s.email = "geoff@garbers.co.za"
  s.homepage = "https://github.com/garbetjie/logstash-output-stackdriver_logging"
  s.require_paths = %w(lib generated)

  # Files
  s.files = Dir['lib/**/*','spec/**/*','vendor/**/*','*.gemspec','*.md','CONTRIBUTORS','Gemfile','LICENSE','NOTICE.TXT']
   # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "output" }

  # Gem dependencies
  #
  s.add_runtime_dependency "logstash-core-plugin-api", ">= 1.60", "<= 2.99"
  s.add_runtime_dependency "logstash-codec-plain"
  s.add_runtime_dependency "google-api-client"
  s.add_runtime_dependency "googleauth"
  s.add_development_dependency 'logstash-devutils'
end
