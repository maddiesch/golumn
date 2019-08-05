require 'logger'

module Golumn
  class Formatter < ::Logger::Formatter
    BLINDER = Regexp.new('\e\[(\d+)(;\d+)*m').freeze
    DATE_FORMAT = '%Y-%m-%dT%H:%M:%S.%L'.freeze

    def call(severity, timestamp, _progname, msg)
      msg = (msg.is_a?(String) ? msg : msg.inspect).gsub(BLINDER, '')
      "#{timestamp.utc.strftime(DATE_FORMAT)} [#{severity}] #{msg}\n"
    end
  end
end
