# frozen_string_literal: true

describe AfricaCheck do
  describe 'instance' do
    it 'has a hostname' do
      expect(described_class.new.hostname).to(eq('https://africacheck.org'))
    end

    it 'has a fact_list_path' do
      expect(described_class.new.fact_list_path(1)).to(eq('/fact-checks?field_article_type_value=reports&field_rated_value=All&field_country_value=All&sort_bef_combine=created_DESC&sort_by=created&sort_order=DESC&page=1'))
    end

    it 'has a url_extraction_search' do
      expect(described_class.new.url_extraction_search).to(eq('article'))
    end

    it 'rescues against a claim_review_image_url_from_raw_claim_review' do
      expect(described_class.new.claim_review_image_url_from_raw_claim_review({"page" => Nokogiri.parse("<article about='/blah'>wow</article>")})).to(eq(nil))
    end

    it 'extracts a url' do
      expect(described_class.new.url_extractor(Nokogiri.parse("<article about='/blah'>wow</article>").search('article')[0])).to(eq(described_class.new.hostname+'/blah'))
    end

    it 'expects a claim_result_text_map' do
      expect(described_class.new.rating_map.class).to(eq(Hash))
    end

    it 'stubs the resposne for a nil get_claim_review_from_raw_claim_review' do
      expect(described_class.new.parse_raw_claim_review({"url" => "blah"})).to(eq({id: "blah"}))
    end

    it 'parses a raw_claim_review' do
      raw = JSON.parse(File.read('spec/fixtures/africa_check_raw.json'))
      raw['page'] = Nokogiri.parse(raw['page'])
      parsed_claim = described_class.new.parse_raw_claim_review(raw)
      expect(parsed_claim.class).to(eq(Hash))
      ClaimReview.mandatory_fields.each do |field|
        expect(QuietHashie[parsed_claim][field].nil?).to(eq(false))
      end
    end
  end
end
