# frozen_string_literal: true
describe Globo do
  before do
    stub_request(:get, "https://www.vishvasnews.com/blah").
      with(
        headers: {
    	  'Accept'=>'*/*',
    	  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
    	  'Host'=>'www.vishvasnews.com',
    	  'User-Agent'=>/.*/
        }).
      to_return(status: 200, body: JSON.parse(File.read('spec/fixtures/globo_raw.json'))["page"], headers: {})
  end

  describe 'instance' do
    it 'has a hostname' do
      expect(described_class.new.hostname).to(eq('https://falkor-cda.bastian.globo.com'))
    end

    it 'has a fact_list_path' do
      expect(described_class.new.fact_list_path(1)).to(eq('/tenants/g1/instances/9a0574d8-bc61-4d35-9488-7733f754f881/posts/page/1'))
    end

    it 'extracts a url' do
      expect(described_class.new.url_extractor({"items" => [{"url" => "/blah"}]})).to(eq([{"url" => "/blah"}]))
    end

    it 'extracts raw responses from get_new_fact_page_urls' do
      described_class.any_instance.stub(:get_fact_page_urls).with(1).and_return([{"content" => {"url" => "/blah"}}])
      described_class.any_instance.stub(:get_existing_urls).with(anything()).and_return([])
      expect(described_class.new.get_new_fact_page_urls(1)).to(eq([{"content"=>{"url"=>"/blah"}}]))
    end

    it 'tests false result for headline' do
      response = described_class.new.claim_review_result_from_api_response({"content" => {"title" => "É #FATO que imagens mostrem caminhões descartando cédulas com votos em Donald Trump em local descampado"}})
      expect(response).to(eq([1, "true"]))
    end

    it 'tests true result for headline' do
      response = described_class.new.claim_review_result_from_api_response({"content" => {"title" => "É #FAKE que imagens mostrem caminhões descartando cédulas com votos em Donald Trump em local descampado"}})
      expect(response).to(eq([0, "false"]))
    end
    it 'extracts parsed_fact_page results' do
      keys = [:author, :author_link, :claim_review_body, :claim_review_headline, :claim_review_image_url, :claim_review_result, :claim_review_result_score, :claim_review_reviewed, :claim_review_url, :created_at, :id, :raw_claim_review].sort
      response = described_class.new.parsed_fact_page({"created" => "2020-01-01", "content" => {"url" => described_class.new.hostname+"/blah"}})
      expect(response[0]).to(eq('https://falkor-cda.bastian.globo.com/blah'))
      expect(response[1].class).to(eq(Hash))
      expect(response[1].keys.sort).to(eq(keys))
    end

    it 'parses a raw_claim_review' do
      raw = JSON.parse(File.read('spec/fixtures/globo_raw.json'))
      parsed_claim = described_class.new.parse_raw_claim_review(raw)
      expect(parsed_claim.class).to(eq(Hash))
      ClaimReview.mandatory_fields.each do |field|
        expect(QuietHashie[parsed_claim][field].nil?).to(eq(false))
      end
    end
  end
end
