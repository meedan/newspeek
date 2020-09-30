# frozen_string_literal: true

describe Factly do
  before do
    stub_request(:get, JSON.parse(File.read('spec/fixtures/factly_raw.json'))["url"])
      .with(
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Host' => 'factly.in',
          'User-Agent' => /.*/
        }
      )
      .to_return(status: 200, body: JSON.parse(File.read('spec/fixtures/factly_raw.json'))["page"], headers: {})
  end
  describe 'instance' do
    it 'extracts raw responses from get_new_fact_page_urls' do
      described_class.any_instance.stub(:get_fact_page_urls).with(1).and_return([{'link' => '/blah', 'categories' => [123]}, {'link' => '/blah2', 'categories' => [305]}])
      described_class.any_instance.stub(:get_existing_urls).with(anything()).and_return([])
      expect(described_class.new.get_new_fact_page_urls(1)).to(eq([{"categories"=>[123], "link"=>"/blah"}, {'link' => '/blah2', 'categories' => [305]}]))
    end

    it 'extracts parsed_fact_page results' do
      keys = [:author, :author_link, :claim_review_body, :claim_review_headline, :claim_review_image_url, :claim_review_result, :claim_review_result_score, :claim_review_url, :created_at, :id, :raw_claim_review].sort
      raw = JSON.parse(File.read('spec/fixtures/factly_raw.json'))
      raw["raw_response"].delete("_links")
      response = described_class.new.parsed_fact_page(raw["raw_response"])
      expect(response[0]).to(eq(raw['url']))
      expect(response[1].class).to(eq(Hash))
      expect(response[1].keys.sort).to(eq(keys))
    end
    
    it 'has a hostname' do
      expect(described_class.new.hostname).to(eq('https://factly.in'))
    end

    it 'has a fact_list_path' do
      expect(described_class.new.fact_list_path(1)).to(eq('/wp-json/wp/v2/posts?page=1'))
    end

    it 'extracts a url' do
      expect(described_class.new.url_extractor([{'categories' => [123]}, {'categories' => [305]}])).to(eq([{'categories' => [305]}]))
    end

    it 'rescues against a claim_review_image_url_from_raw_claim_review' do
      expect(described_class.new.claim_review_image_url_from_raw_claim_review({"page" => Nokogiri.parse("<a href='/blah'>wow</a>")})).to(eq(nil))
    end

    it 'parses a raw_claim_review' do
      raw = JSON.parse(File.read('spec/fixtures/factly_raw.json'))
      raw["raw_response"].delete("_links")
      raw['page'] = Nokogiri.parse(raw['page'])
      parsed_claim = described_class.new.parse_raw_claim_review(raw)
      expect(parsed_claim.class).to(eq(Hash))
      ClaimReview.mandatory_fields.each do |field|
        expect(Hashie::Mash[parsed_claim][field].nil?).to(eq(false))
      end
    end
  end
end
