# frozen_string_literal: true
describe VishvasNews do
  before do
    stub_request(:get, "https://www.vishvasnews.com/blah").
      with(
        headers: {
    	  'Accept'=>'*/*',
    	  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
    	  'Host'=>'www.vishvasnews.com',
    	  'User-Agent'=>/.*/
        }).
      to_return(status: 200, body: JSON.parse(File.read('spec/fixtures/vishvas_news_raw.json'))["page"], headers: {})
  end

  describe 'instance' do
    it 'has a hostname' do
      expect(described_class.new.hostname).to(eq('https://www.vishvasnews.com'))
    end

    it 'has a fact_list_path' do
      expect(described_class.new.fact_list_path(1)).to(eq('/jsonfeeds/?task=whatsapplatest&page=1&limit=50'))
    end

    it 'extracts a url' do
      expect(described_class.new.url_extractor({"response" => {"docs" => [{"link" => "/blah"}]}})).to(eq([{"link"=>"/blah"}]))
    end

    it 'extracts raw responses from get_new_fact_page_urls' do
      described_class.any_instance.stub(:get_fact_page_urls).with(1).and_return([{"link" => "/blah"}])
      described_class.any_instance.stub(:get_existing_urls).with(anything()).and_return([])
      expect(described_class.new.get_new_fact_page_urls(1)).to(eq([{"link"=>"/blah"}]))
    end

    it 'extracts parsed_fact_page results' do
      keys = [:author, :author_link, :claim_review_body, :claim_review_headline, :claim_review_image_url, :claim_review_result, :claim_review_result_score, :claim_review_reviewed, :claim_review_url, :created_at, :id, :raw_claim_review].sort
      response = described_class.new.parsed_fact_page({"link"=>described_class.new.hostname+"/blah"})
      expect(response[0]).to(eq('https://www.vishvasnews.com/blah'))
      expect(response[1].class).to(eq(Hash))
      expect(response[1].keys.sort).to(eq(keys))
    end

    it 'parses a raw_claim_review' do
      raw = JSON.parse(File.read('spec/fixtures/vishvas_news_raw.json'))
      raw['page'] = Nokogiri.parse(raw['page'])
      parsed_claim = described_class.new.parse_raw_claim_review(raw)
      expect(parsed_claim.class).to(eq(Hash))
      ClaimReview.mandatory_fields.each do |field|
        expect(QuietHashie[parsed_claim][field].nil?).to(eq(false))
      end
    end
  end
end
