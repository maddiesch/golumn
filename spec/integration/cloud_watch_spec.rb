require 'spec_helper'

RSpec.describe 'CloudWatch' do
  let(:client) { Aws::CloudWatchLogs::Client.new(stub_responses: true) }

  subject { Golumn::Targets::CloudWatch.new(client: client) }

  it { expect { subject.debug 'Testing' }.to_not raise_error }

  it 'makes expected requests' do
    subject.debug 'testing'
    subject.info 'testing'

    subject.close

    requests = client.api_requests.map { |r| [r[:operation_name], r[:params]] }

    expect(requests[0].first).to eq :create_log_stream
    expect(requests[1].first).to eq :put_log_events
    expect(requests[1].last.dig(:log_events, 0, :message)).to match(/\[DEBUG\] testing\n\z/)
    expect(requests[1].last.dig(:log_events, 1, :message)).to match(/\[INFO\] testing\n\z/)
  end

  it 'makes expected requests' do
    logger = Golumn::Targets::CloudWatch.new(client: client, batch_size: 2)

    logger.debug 'testing'
    logger.info 'testing'
    logger.warn 'testing'

    logger.close

    requests = client.api_requests.map { |r| [r[:operation_name], r[:params]] }

    expect(requests[0].first).to eq :create_log_stream
    expect(requests[1].first).to eq :put_log_events
    expect(requests[1].last.dig(:log_events, 0, :message)).to match(/\[DEBUG\] testing\n\z/)
    expect(requests[1].last.dig(:log_events, 1, :message)).to match(/\[INFO\] testing\n\z/)
    expect(requests[1].first).to eq :put_log_events
    expect(requests[2].last.dig(:log_events, 0, :message)).to match(/\[WARN\] testing\n\z/)
  end
end
