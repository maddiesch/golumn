require 'logger'
require 'pry'
require 'aws-sdk-cloudwatchlogs'

require_relative '../worker'
require_relative '../formatter'
require_relative '../metadata'

module Golumn
  module Targets
    class CloudWatch < ::Logger
      class Device
        def initialize(group_name: nil, stream_name: nil, client: nil, opts: {})
          @group_name = group_name || [Golumn::Metadata.application_name, Golumn::Metadata.environment].join('-')
          @stream_name = stream_name || create_stream_name
          @client = client || Aws::CloudWatchLogs::Client.new
          @worker = Golumn::Worker.new do |messages|
            MessageWorker.new(
              group_name: @group_name,
              stream_name: @stream_name,
              client: @client,
              messages: messages
            ).call
          end
          SetupWorker.new(opts.merge(client: @client, group_name: @group_name, stream_name: @stream_name)).call
        end

        def write(message)
          @worker.perform(message)
        end

        def close
          @worker.exit!
          @worker.join
        end

        private

        def create_stream_name
          [
            Time.now.utc.strftime('%Y/%m/%d'),
            Digest::MD5.hexdigest(Socket.gethostname),
            Process.pid.to_s
          ].join('/')
        end
      end

      class SetupWorker
        def initialize(options)
          @client = options.delete(:client)
          @options = options.merge(count: 0)
        end

        def call
          @options[:count] = @options[:count] + 1

          @client.create_log_stream(
            log_group_name: @options.fetch(:group_name),
            log_stream_name: @options.fetch(:stream_name)
          )
          true
        rescue Aws::CloudWatchLogs::Errors::ResourceNotFoundException => e
          raise e if @options.fetch(:count) > 1

          @client.create_log_group(
            log_group_name: @options.fetch(:group_name)
          )
          @client.put_retention_policy(
            log_group_name: @options.fetch(:group_name),
            retention_in_days: @options.fetch(:retention_in_days, 7)
          )
          retry
        rescue Aws::CloudWatchLogs::Errors::ResourceAlreadyExistsException
          true
        end
      end

      class MessageWorker
        SEQUENCE_TOKEN = :__golumn_next_sequence_token

        def initialize(options)
          @client = options.delete(:client)
          @options = options
          @time = (Time.now.utc.to_f.round(3) * 1000).to_i
        end

        def call
          response = @client.put_log_events(
            log_group_name: @options.fetch(:group_name),
            log_stream_name: @options.fetch(:stream_name),
            sequence_token: Thread.current[SEQUENCE_TOKEN],
            log_events: @options.fetch(:messages).map do |message|
              { timestamp: @time, message: message }
            end
          )
          Thread.current[SEQUENCE_TOKEN] = response.next_sequence_token
        end
      end

      def initialize(options = {})
        formatter = options.delete(:formatter) || Golumn::Formatter.new

        super(Device.new(options), formatter: formatter)
      end
    end
  end
end
