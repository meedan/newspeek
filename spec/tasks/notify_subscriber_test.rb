# frozen_string_literal: true

describe NotifySubscriber do
  before do
    stub_request(:post, "http://blah.com/respond").
    with(
      body: /.*/,
      headers: {
  	  'Accept'=>'*/*',
  	  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
  	  'Content-Length'=>/.*/,
  	  'Host'=>'blah.com',
  	  'User-Agent'=>/.*/
      }).
    to_return(status: 200, body: "", headers: {})
  end

  describe 'instance' do
    it 'responds to perform' do
      Subscription.stub(:get_subscriptions).with('blah').and_return(['http://blah.com/respond'])
      expect(described_class.new.perform('blah', {})).to(eq(['http://blah.com/respond']))
    end
  end
end
