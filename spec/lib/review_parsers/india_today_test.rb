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

    it 'parses a raw_claim' do
      raw = JSON.parse(File.read('spec/fixtures/india_today_raw.json'))
      raw['page'] = Nokogiri.parse(raw['page'])
      parsed_claim = described_class.new.parse_raw_claim(raw)
      expect(parsed_claim.class).to(eq(Hash))
      ClaimReview.mandatory_fields.each do |field|
        expect(Hashie::Mash[parsed_claim][field].nil?).to(eq(false))
      end
    end

    it 'properly rescues claim_result_and_score_from_page' do
      expect(IndiaToday.new.claim_result_and_score_from_page(Nokogiri.parse(''))).to(eq(['Inconclusive', 0.5]))
    end

    it 'properly rescues time_from_page' do
      expect(IndiaToday.new.time_from_page(Nokogiri.parse(''))).to(eq(nil))
    end
  end
end
