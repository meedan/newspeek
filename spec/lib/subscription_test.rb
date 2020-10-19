# frozen_string_literal: true

describe Subscription do
  before do
    stub_request(:post, "http://blah.com/respond").
    with(
      body: "{\"claim_review\":{}}",
      headers: {
  	  'Accept'=>'*/*',
  	  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
  	  'Content-Length'=>/.*/,
  	  'Host'=>'blah.com',
  	  'User-Agent'=>/.*/
      }).
    to_return(status: 200, body: "", headers: {})
  end
  describe 'class' do
    it 'responds to keyname' do
      expect(described_class.keyname('blah')).to(eq('claim_review_webhooks_blah'))
    end

    it 'responds to add_subscription' do
      expect(described_class.add_subscription('blah', 'http://blah.com/respond')).to(eq([true]))
    end

    it 'responds to remove_subscription' do
      expect(described_class.remove_subscription('blah', 'http://blah.com/respond')).to(eq([true]))
    end

    it 'responds to get_subscriptions' do
      expect(described_class.get_subscriptions('blah').class).to(eq(Array))
    end

    it 'responds to notify_subscribers' do
      described_class.stub(:get_subscriptions).with('blah').and_return(['http://blah.com/respond'])
      expect(described_class.notify_subscribers('blah', {}).class).to(eq(Array))
    end

    it 'responds to notify_subscribers' do
      described_class.stub(:get_subscriptions).with('blah').and_return(['http://blah.com/respond'])
      described_class.stub(:send_webhook_notification).with('http://blah.com/respond', {}).and_raise(RestClient::ServiceUnavailable)
      expect { described_class.notify_subscribers('blah', {}) }.to raise_error(RestClient::ServiceUnavailable)
    end
  end
end
