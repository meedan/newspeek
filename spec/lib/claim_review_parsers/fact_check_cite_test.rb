# frozen_string_literal: true

describe FactCheckCite do
  before do
    stub_request(:post, "https://factcheck.cite.org.zw/wp-json/csco/v1/more-posts").
      with(
        body: {"action"=>"csco_ajax_load_more", "page"=>"1", "posts_per_page"=>"10"},
        headers: {
    	  'Accept'=>'*/*',
    	  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
    	  'Content-Length'=>'51',
    	  'Content-Type'=>'application/x-www-form-urlencoded',
    	  'Host'=>'factcheck.cite.org.zw',
    	  'User-Agent'=>'rest-client/2.1.0 (linux x86_64) ruby/2.7.3p183'
        }).
      to_return(status: 200, body: '{"data": {"content": "<article><a href=\"/blah\">blah</a></article><article><a href=\"/blah2\">blah2</a></article>"}}', headers: {})
  end

  describe 'instance' do
    it 'has a hostname' do
      expect(described_class.new.hostname).to(eq('https://factcheck.cite.org.zw/wp-json/csco/v1/more-posts'))
    end

    it 'requests a fact page' do
      expect(described_class.new.request_fact_page(1, 10).class).to(eq(RestClient::Response))      
    end

    it 'gets urls from a fact page' do
      expect(described_class.new.get_page_urls(1, 10)).to(eq(["/blah", "/blah2"]))
    end

    it 'gets a created_at from a raw_claim_review' do
      expect(described_class.new.created_at_from_raw_claim_review({"page" => Nokogiri.parse("<html><body><div id='primary'><div class='cs-meta-date'>29/01/2021</div></div></body></html>")})).to(eq("29/01/2021"))
    end

    it 'returns get_new_fact_page_urls' do
      described_class.any_instance.stub(:get_existing_urls).with(anything).and_return([])
      expect(described_class.new.get_new_fact_page_urls(1)).to(eq(["/blah", "/blah2"]))
    end

    it 'parses a raw_claim_review' do
      raw = JSON.parse(File.read('spec/fixtures/fact_check_cite_raw.json'))
      raw['page'] = Nokogiri.parse(raw['page'])
      parsed_claim = described_class.new.parse_raw_claim_review(raw)
      expect(parsed_claim.class).to(eq(Hash))
      ClaimReview.mandatory_fields.each do |field|
        expect(QuietHashie[parsed_claim][field].nil?).to(eq(false))
      end
    end
  end
end
