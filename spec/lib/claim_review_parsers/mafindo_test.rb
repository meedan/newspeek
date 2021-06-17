# frozen_string_literal: true
describe Mafindo do
  before do
    stub_request(:post, "https://yudistira.turnbackhoax.id/api/antihoax/get_authors").
      with(
        body: /.*/,
        headers: {
    	  'Accept'=>'*/*',
    	  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
    	  'Content-Length'=>/.*/,
    	  'Content-Type'=>'application/x-www-form-urlencoded',
    	  'Host'=>'yudistira.turnbackhoax.id',
    	  'User-Agent'=>/.*/
        }).
      to_return(status: 200, body: '[{"id":36,"website":"blah","nama":"foo"}]', headers: {})
    stub_request(:post, "https://yudistira.turnbackhoax.id/api/antihoax").
      with(
        body: /.*/,
        headers: {
    	  'Accept'=>'*/*',
    	  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
    	  'Content-Length'=>/.*/,
    	  'Content-Type'=>'application/x-www-form-urlencoded',
    	  'Host'=>'yudistira.turnbackhoax.id',
    	  'User-Agent'=>/.*/
        }).
      to_return(status: 200, body: File.read('spec/fixtures/mafindo_raw.json'), headers: {})

  end

  describe 'instance' do
    it 'has a hostname' do
      expect(described_class.new.hostname).to(eq('https://yudistira.turnbackhoax.id/api'))
    end

    it 'has a fact_list_path' do
      expect(described_class.new.fact_list_path).to(eq('/antihoax'))
    end

    it 'gets a fact page' do
      expect(described_class.new.request_fact_page(1, 200).body).to(eq(File.read('spec/fixtures/mafindo_raw.json')))
    end

    it 'parses a fact page' do
      expect(described_class.new.get_fact_page_response(1)).to(eq(JSON.parse(File.read('spec/fixtures/mafindo_raw.json'))))
    end
    
    it 'ensures a service_key' do
      expect(described_class.new.service_key).to(eq('mafindo_api_key'))
    end

    it 'runs get_claim_reviews' do
      RestClient.stub(:get).with(anything).and_return(RestClient::Response.new('{}'))
      described_class.any_instance.stub(:service_key_is_needed?).and_return(false)
      ClaimReview.stub(:existing_urls).with(anything, anything).and_return([])
      ClaimReview.stub(:existing_ids).with(anything, anything).and_return([])
      ClaimReviewParser.any_instance.stub(:store_to_db).with(anything, anything).and_return([])
      raw = JSON.parse(File.read('spec/fixtures/mafindo_raw.json'))
      described_class.any_instance.stub(:get_fact_page_response).with(1).and_return([raw])
      described_class.any_instance.stub(:get_fact_page_response).with(2).and_return([])
      expect(described_class.new.get_claim_reviews).to(eq(nil))
    end
  end
end
