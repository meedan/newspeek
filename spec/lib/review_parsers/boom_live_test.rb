# frozen_string_literal: true

describe BoomLive do
  describe 'instance' do
    it 'walks through get_stories_by_category' do
      RestClient.stub(:get).with(anything, described_class.new.api_params).and_return(File.read('spec/fixtures/boom_live_raw.json'))
      expect(described_class.new.get_stories_by_category(1, 1, 1).class).to(eq(Hash))
    end

    it 'walks through get_new_stories_by_category' do
      RestClient.stub(:get).with(anything, described_class.new.api_params).and_return({ 'news' => [JSON.parse(File.read('spec/fixtures/boom_live_raw.json'))] }.to_json)
      ClaimReview.stub(:existing_urls).with(anything, anything).and_return([])
      expect(described_class.new.get_new_stories_by_category(1, 1).class).to(eq(Array))
    end
    it 'walks through store_claims_for_category_id_and_page' do
      described_class.any_instance.stub(:get_new_stories_by_category).and_return([{}])
      described_class.new.store_claims_for_category_id_and_page(1, 1)
    end

    it 'walks through get_all_stories_by_category' do
      described_class.any_instance.stub(:store_claims_for_category_id_and_page).with(1, 1).and_return([{}])
      described_class.any_instance.stub(:store_claims_for_category_id_and_page).with(1, 2).and_return([])
      expect(described_class.new.get_all_stories_by_category(1)).to(eq(nil))
    end

    it 'walks through get_claims' do
      described_class.any_instance.stub(:get_all_stories_by_category).with(anything).and_return([{}])
      expect(described_class.new.get_claims).to(eq(described_class.new.fact_categories))
    end

    it 'rescues get_claim_result_for_raw_claim' do
      RestClient.stub(:get).with(anything).and_return("<html><div class='claim-review-block'><div class='claim-value'>Fact check</div></div></html>")
      expect(described_class.new.get_claim_result_for_raw_claim({})).to(eq(nil))
    end

    it 'walks through get_path' do
      RestClient.stub(:get).with(anything, described_class.new.api_params).and_return(File.read('spec/fixtures/boom_live_raw.json'))
      expect(described_class.new.get_path('123').class).to(eq(Hash))
    end
    it 'has a hostname' do
      expect(described_class.new.hostname).to(eq('http://boomlive.in/'))
    end

    it 'has fact_categories' do
      expect(described_class.new.fact_categories.class).to(eq(Hash))
    end

    it 'parses a raw_claim' do
      raw = JSON.parse(File.read('spec/fixtures/boom_live_raw.json'))
      RestClient.stub(:get).with(raw['url']).and_return("<html><div class='claim-review-block'><div class='claim-value'>fact check <span class='value'>False</span></div></div></html>")
      parsed_claim = described_class.new.parse_raw_claim(raw)
      expect(parsed_claim.class).to(eq(Hash))
      ClaimReview.mandatory_fields.each do |field|
        expect(Hashie::Mash[parsed_claim][field].nil?).to(eq(false))
      end
    end
  end
end
