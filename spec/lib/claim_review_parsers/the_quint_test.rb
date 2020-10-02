# frozen_string_literal: true

describe TheQuint do
  describe 'instance' do
    it 'parses get_claim_reviews_for_page' do
      raw = JSON.parse(File.read('spec/fixtures/the_quint_raw.json'))
      raw["story"].delete("cards")
      RestClient.stub(:get).with(anything).and_return({ 'items' => [raw] }.to_json)
      expect(described_class.new.get_claim_reviews_for_page(1).class).to(eq(Array))
    end

    it 'has a hostname' do
      expect(described_class.new.hostname).to(eq('https://www.thequint.com'))
    end

    it 'has a fact_list_path' do
      expect(described_class.new.fact_list_path(1)).to(eq('/api/v1/collections/webqoof?item-type=story&offset=0&limit=100'))
    end

    it 'parses a raw_claim_review' do
      raw = JSON.parse(File.read('spec/fixtures/the_quint_raw.json'))
      raw["story"].delete("cards")
      parsed_claim = described_class.new.parse_raw_claim_review(raw)
      expect(parsed_claim.class).to(eq(Hash))
      ClaimReview.mandatory_fields.each do |field|
        expect(QuietHashie[parsed_claim][field].nil?).to(eq(false))
      end
    end

    it 'walks through get_new_claim_reviews_for_page' do
      raw = JSON.parse(File.read('spec/fixtures/the_quint_raw.json'))
      raw["story"].delete("cards")
      RestClient.stub(:get).with(anything).and_return({ 'items' => [] }.to_json)
      ClaimReview.stub(:existing_urls).with(anything, described_class.service).and_return([])
      ClaimReview.stub(:existing_ids).with(anything, described_class.service).and_return([])
      ClaimReviewRepository.any_instance.stub(:save).with(anything).and_return({ _index: 'claim_reviews', _type: 'claim_review', _id: 'vhV84XIBOGf2XeyOAD12', _version: 1, result: 'created', _shards: { total: 2, successful: 1, failed: 0 }, _seq_no: 130_821, _primary_term: 2 })
      expect(described_class.new.get_claim_reviews).to(eq(nil))
    end

    it 'walks through get_claim_reviews' do
      described_class.any_instance.stub(:get_new_claim_reviews_for_page).with(1).and_return([{}])
      described_class.any_instance.stub(:get_new_claim_reviews_for_page).with(2).and_return([])
      ClaimReview.stub(:existing_urls).with(anything, described_class.service).and_return([])
      expect(described_class.new.get_claim_reviews).to(eq(nil))
    end

    it 'rescues from claim_image_url_from_raw_claim_review' do
      expect(described_class.new.claim_image_url_from_raw_claim_review({})).to(eq(nil))
    end
    it 'rescues from created_at_from_raw_claim_review' do
      expect(described_class.new.created_at_from_raw_claim_review({})).to(eq(nil))
    end

    it 'rescues from claim_url_from_raw_claim_review' do
      expect(described_class.new.claim_url_from_raw_claim_review({})).to(eq(nil))
    end

    it 'rescues from claim_headline_from_raw_claim_review' do
      expect(described_class.new.claim_headline_from_raw_claim_review({})).to(eq(nil))
    end

    it 'rescues from claim_body_from_raw_claim_review' do
      expect(described_class.new.claim_body_from_raw_claim_review({})).to(eq(nil))
    end

    it 'rescues from author_from_raw_claim_review' do
      expect(described_class.new.author_from_raw_claim_review({})).to(eq(nil))
    end

    it 'rescues from author_link_from_raw_claim_review' do
      expect(described_class.new.author_link_from_raw_claim_review({})).to(eq(nil))
    end

    it 'rescues from claim_result_from_raw_claim_review' do
      expect(described_class.new.claim_result_from_raw_claim_review(nil)).to(eq(nil))
    end

    it 'rescues from claim_result_score_from_raw_claim_review' do
      expect(described_class.new.claim_result_score_from_raw_claim_review(nil)).to(eq(nil))
    end
  end
end
