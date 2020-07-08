# frozen_string_literal: true

describe Tattle do
  describe 'instance' do
    it 'parses a raw_claim_review' do
      raw = JSON.parse(File.read('spec/fixtures/tattle_raw.json'))
      parsed_claim = described_class.new.parse_raw_claim_review(raw)
      expect(parsed_claim.class).to(eq(Hash))
      ClaimReview.mandatory_fields.each do |field|
        expect(Hashie::Mash[parsed_claim][field].nil?).to(eq(false))
      end
    end

    it 'parses the in-repo dataset' do
      single_case = JSON.parse(File.read('spec/fixtures/tattle_raw.json'))
      File.stub(:read).with(described_class.dataset_path).and_return([single_case].to_json)
      ClaimReview.stub(:existing_urls).with([single_case['Post URL']], described_class.service).and_return([])
      ClaimReview.stub(:existing_ids).with([single_case['Post URL']], described_class.service).and_return([])
      ClaimReviewRepository.any_instance.stub(:save).with(anything).and_return({ _index: 'claim_reviews', _type: 'claim_review', _id: 'vhV84XIBOGf2XeyOAD12', _version: 1, result: 'created', _shards: { total: 2, successful: 1, failed: 0 }, _seq_no: 130_821, _primary_term: 2 })
      expect(described_class.new.get_claim_reviews).to(eq(nil))
    end

    it 'parses the in-repo dataset with no content' do
      single_case = JSON.parse(File.read('spec/fixtures/tattle_raw.json'))
      single_case['Docs'] = []
      File.stub(:read).with(described_class.dataset_path).and_return([single_case].to_json)
      ClaimReview.stub(:existing_urls).with([single_case['Post URL']], described_class.service).and_return([])
      ClaimReview.stub(:existing_ids).with([single_case['Post URL']], described_class.service).and_return([])
      ClaimReviewRepository.any_instance.stub(:save).with(anything).and_return({ _index: 'claim_reviews', _type: 'claim_review', _id: 'vhV84XIBOGf2XeyOAD12', _version: 1, result: 'created', _shards: { total: 2, successful: 1, failed: 0 }, _seq_no: 130_821, _primary_term: 2 })
      expect(described_class.new.get_claim_reviews).to(eq(nil))
    end
  end
end
