# frozen_string_literal: true

describe IndiaToday do
  describe 'instance' do
    it 'has a hostname' do
      expect(described_class.new.hostname).to(eq('https://www.indiatoday.in'))
    end

    it 'has a fact_list_path' do
      expect(described_class.new.fact_list_path(1)).to(eq('/fact-check?page=0'))
    end

    it 'has a url_extraction_search' do
      expect(described_class.new.url_extraction_search).to(eq('div.detail h2 a'))
    end

    it 'extracts a url' do
      expect(described_class.new.url_extractor(Nokogiri.parse("<a href='/blah'>wow</a>").search('a')[0])).to(eq('https://www.indiatoday.in/blah'))
    end

    it 'stubs the resposne for a nil get_claim_review_from_raw_claim_review' do
      expect(described_class.new.claim_review_from_raw_claim_review({"page" => Nokogiri.parse("<a href='/blah'>wow</a>")})).to(eq({}))
    end

    it 'parses a raw_claim_review' do
      raw = JSON.parse(File.read('spec/fixtures/india_today_raw.json'))
      raw['page'] = Nokogiri.parse(raw['page'])
      parsed_claim = described_class.new.parse_raw_claim_review(raw)
      expect(parsed_claim.class).to(eq(Hash))
      ClaimReview.mandatory_fields.each do |field|
        expect(QuietHashie[parsed_claim][field].nil?).to(eq(false))
      end
    end

    it 'parses a raw_claim_review with mixed ld+json block types' do
      raw = JSON.parse(File.read('spec/fixtures/india_today_mixed_ld_json_types.json'))
      raw['page'] = Nokogiri.parse(raw['page'])
      parsed_claim = described_class.new.parse_raw_claim_review(raw)
      expect(parsed_claim.class).to(eq(Hash))
      ClaimReview.mandatory_fields.each do |field|
        expect(QuietHashie[parsed_claim][field].nil?).to(eq(false))
      end
    end

    it 'stubs a raw_claim_review response' do
      raw = {"page" => Nokogiri.parse("<a href='/blah'>wow</a>"), "url" => "blah"}
      parsed_claim = described_class.new.parse_raw_claim_review(raw)
      expect(parsed_claim.class).to(eq(Hash))
    end

  end
end
