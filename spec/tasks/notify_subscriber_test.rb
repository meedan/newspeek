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
    stub_request(:post, "http://blah.com/respond2").
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
      Subscription.add_subscription("blah", "http://blah.com/respond", "en")
      Subscription.add_subscription("blah", "http://blah.com/respond2")
      response = described_class.new.perform('blah', {})
      Subscription.remove_subscription("blah", "http://blah.com/respond")
      Subscription.remove_subscription("blah", "http://blah.com/respond2")
      expect(response).to(eq([{"http://blah.com/respond"=>{"language"=>["en"]}, "http://blah.com/respond2"=>{"language"=>[]}}]))
    end
  end
end
