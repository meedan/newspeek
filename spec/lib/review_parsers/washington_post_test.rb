# frozen_string_literal: true

describe WashingtonPost do
  describe 'instance' do
    it 'parses list_pages in json' do
      expect(described_class.new.fact_list_page_parser).to(eq('json'))
    end

    it 'has a hostname' do
      expect(described_class.new.hostname).to(eq('https://www.washingtonpost.com'))
    end

    it 'has a fact_list_path' do
      expect(described_class.new.fact_list_path(1)).to(eq('/pb/api/v2/render/feature/section/story-list?addtl_config=blog-front&content_origin=content-api-query&size=10&from=0&primary_node=/politics/fact-checker'))
    end

    it 'has a url_extractor' do
      expect(described_class.new.url_extractor({ 'rendering' => "<div class='story-headline'><h2><a href='/blah'>wow</a></h2></div>" })).to(eq(['https://www.washingtonpost.com/blah']))
    end

    it 'parses a raw_claim_review' do
      raw = JSON.parse(File.read('spec/fixtures/washington_post_raw.json'))
      raw['page'] = Nokogiri.parse(raw['page'])
      parsed_claim = described_class.new.parse_raw_claim_review(raw)
      expect(parsed_claim.class).to(eq(Hash))
      ClaimReview.mandatory_fields.each do |field|
        expect(Hashie::Mash[parsed_claim][field].nil?).to(eq(false))
      end
    end

    it 'geppetto extracts correctly' do
      expect(described_class.new.claim_result_and_claim_result_score_from_page(Nokogiri.parse('<h3>Geppetto</h3>'))).to(eq(['True', 1]))
    end

    it 'expects a fully false from claim_result_and_claim_result_score_from_page' do
      expect(described_class.new.claim_result_and_claim_result_score_from_page(Nokogiri.parse('<h3>Pinocchios: Four</h3>'))).to(eq(['False', 0.0]))
    end

    it 'expects a partly false from claim_result_and_claim_result_score_from_page' do
      expect(described_class.new.claim_result_and_claim_result_score_from_page(Nokogiri.parse('<h3>Pinocchios: Three</h3>'))).to(eq(['Partly False', 0.25]))
    end

    it 'expects a rescue from claim_result_and_claim_result_score_from_page' do
      expect(described_class.new.claim_result_and_claim_result_score_from_page(Nokogiri.parse(''))).to(eq(['Inconclusive', 0.5]))
    end

    it 'expects a rescue from author_from_page' do
      expect(described_class.new.author_from_page(Nokogiri.parse(''))).to(eq(nil))
    end

    it 'expects a rescue from author_link_from_page' do
      expect(described_class.new.author_link_from_page(Nokogiri.parse(''))).to(eq(nil))
    end

    it 'expects a rescue from claim_headline_from_page' do
      expect(described_class.new.claim_headline_from_page(Nokogiri.parse(''))).to(eq(nil))
    end

    it 'rescues obviously wrong parse_partial_truthfulness' do
      expect(described_class.new.parse_partial_truthfulness(1, 2)).to(eq(["Inconclusive", 0.5]))
    end
    
    it 'parses array of images for claim_review_image_url_from_news_article' do
      expect(described_class.new.claim_review_image_url_from_news_article({"image" => [{"url" => "blah"}]})).to(eq("blah"))
    end

    it 'parses array of authors for author_from_news_article' do
      expect(described_class.new.author_from_news_article({"author" => [{"name" => "blah"}]})).to(eq("blah"))
    end
  end
end
