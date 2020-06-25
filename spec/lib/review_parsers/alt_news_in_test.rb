# frozen_string_literal: true

describe AltNewsIn do
  describe 'instance' do
    it 'has a hostname' do
      expect(AltNewsIn.new.hostname).to eq('https://www.altnews.in/')
    end

    it 'has a fact_list_path' do
      expect(AltNewsIn.new.fact_list_path(1)).to eq('/page/1/')
    end

    it 'has a url_extraction_search' do
      expect(AltNewsIn.new.url_extraction_search).to eq('div.herald-main-content h2.entry-title a')
    end

    it 'extracts a url' do
      expect(AltNewsIn.new.url_extractor(Nokogiri.parse("<a href='/blah'>wow</a>").search('a')[0])).to eq('/blah')
    end

    it 'parses a raw_claim' do
      raw = JSON.parse(File.read('spec/fixtures/alt_news_in_raw.json'))
      raw['page'] = Nokogiri.parse(raw['page'])
      parsed_claim = AltNewsIn.new.parse_raw_claim(raw)
      expect(parsed_claim.class).to eq(Hash)
      ClaimReview.mandatory_fields.each do |field|
        expect(Hashie::Mash[parsed_claim][field].nil?).to eq(false)
      end
    end
  end
end
