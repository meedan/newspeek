# frozen_string_literal: true

describe Reuters do
  describe 'instance' do
    it 'has a hostname' do
      expect(described_class.new.hostname).to(eq('https://www.reuters.com'))
    end

    it 'has a fact_list_path' do
      expect(described_class.new.fact_list_path(1)).to(eq('/news/archive/reuterscomservice?view=page&page=1&pageSize=10'))
    end

    it 'has a url_extraction_search' do
      expect(described_class.new.url_extraction_search).to(eq('div.column1 section.module-content article.story div.story-content a'))
    end

    it 'extracts a url' do
      expect(described_class.new.url_extractor(Nokogiri.parse("<a href='/blah'>wow</a>").search('a')[0])).to(eq('https://www.reuters.com/blah'))
    end

    it 'rescues p-based claim_result_from_page' do
      expect(described_class.new.claim_result_from_page(Nokogiri.parse("<html><div class='StandardArticleBody_body'><p>Verdict: True</p></div></html>"))).to(eq('True'))
    end

    it 'rescues second p-based claim_result_from_page' do
      expect(described_class.new.claim_result_from_page(Nokogiri.parse("<html><div class='StandardArticleBody_body'><p>verdict True</p></div></html>"))).to(eq('True'))
    end

    it 'rescues claim_result_from_headline' do
      expect(described_class.new.claim_result_from_headline(Nokogiri.parse("<html><div class='StandardArticleBody_body'><h3>verdict True</h3></div></html>"))).to(eq(nil))
    end

    it 'succeeds with claim_result_from_body_inline' do
      expect(described_class.new.claim_result_from_body_inline(Nokogiri.parse("<html><div class='StandardArticleBody_body'><p>verdict True</p></div></html>"))).to(eq("true"))
    end

    it 'rescues claim_result_from_body_inline' do
      expect(described_class.new.claim_result_from_body_inline(Nokogiri.parse("<html><div class='StandardArticleBody_body'><p>True</p></div></html>"))).to(eq(nil))
    end

    it 'rescues claim_result_from_page' do
      expect(described_class.new.claim_result_from_page(Nokogiri.parse(''))).to(eq(nil))
    end

    it 'parses a raw_claim_review' do
      raw = JSON.parse(File.read('spec/fixtures/reuters_raw.json'))
      raw['page'] = Nokogiri.parse(raw['page'])
      parsed_claim = described_class.new.parse_raw_claim_review(raw)
      expect(parsed_claim.class).to(eq(Hash))
      ClaimReview.mandatory_fields.each do |field|
        expect(QuietHashie[parsed_claim][field].nil?).to(eq(false))
      end
    end
  end
end
