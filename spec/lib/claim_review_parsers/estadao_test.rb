# frozen_string_literal: true

describe Estadao do
  describe 'instance' do
    it 'has a hostname' do
      expect(described_class.new.hostname).to(eq('https://politica.estadao.com.br'))
    end

    it 'has a fact_list_path' do
      expect(described_class.new.fact_list_path(1)).to(eq('/blogs/estadao-verifica/page/1/'))
    end

    it 'has a url_extraction_search' do
      expect(described_class.new.url_extraction_search).to(eq('div.paged-content section.custom-news div.box h3.third'))
    end

    it 'extracts a url' do
      expect(described_class.new.url_extractor(Nokogiri.parse("<a href='/blah'><h3>wow</h3></a>").search('h3')[0])).to(eq('/blah'))
    end

    it 'parses a raw_claim_review' do
      raw = JSON.parse(File.read('spec/fixtures/estadao_raw.json'))
      raw['page'] = Nokogiri.parse(raw['page'])
      parsed_claim = described_class.new.parse_raw_claim_review(raw)
      expect(parsed_claim.class).to(eq(Hash))
      ClaimReview.mandatory_fields.each do |field|
        expect(Hashie::Mash[parsed_claim][field].nil?).to(eq(false))
      end
    end
  end
end
