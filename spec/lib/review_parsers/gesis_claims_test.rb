# frozen_string_literal: true

describe GESISClaims do
  describe 'instance' do
    it 'runs get_all_fact_ids' do
      described_class.any_instance.stub(:get_fact_ids).with(1).and_return(['123'])
      described_class.any_instance.stub(:get_fact_ids).with(2).and_return(['456'])
      described_class.any_instance.stub(:get_fact_ids).with(3).and_return([])
      expect(described_class.new.get_all_fact_ids).to(eq(%w[123 456]))
    end

    it 'parses get_fact_ids' do
      RestClient.stub(:post).with(anything, anything, anything).and_return({ 'results' => { 'bindings' => [{ 'id' => { 'value' => '/123' } }] } }.to_json)
      expect(described_class.new.get_fact_ids(1)).to(eq([%w[123 202cb962ac59075b964b07152d234b70]]))
    end

    it 'walks through the get_request' do
      RestClient.stub(:post).with(anything, anything, anything).and_return({}.to_json)
      expect(described_class.new.get_fact('123')).to(eq({}))
    end

    it 'runs through get_claims' do
      raw = JSON.parse(File.read('spec/fixtures/gesis_claims_raw.json'))['content']
      described_class.any_instance.stub(:get_all_fact_ids).and_return([[raw['id']['value'].split('/').last, Digest::MD5.hexdigest(raw['id']['value'].split('/').last)]])
      ClaimReview.stub(:existing_ids).with([Digest::MD5.hexdigest(raw['id']['value'].split('/').last)], described_class.service).and_return([])
      RestClient.stub(:post).with(anything, anything, anything).and_return({ 'results' => { 'bindings' => [raw] } })
      described_class.any_instance.stub(:get_fact).with(raw['id']['value'].split('/').last).and_return(raw)
      ClaimReviewRepository.any_instance.stub(:save).with(anything).and_return({ _index: 'claim_reviews', _type: 'claim_review', _id: 'vhV84XIBOGf2XeyOAD12', _version: 1, result: 'created', _shards: { total: 2, successful: 1, failed: 0 }, _seq_no: 130_821, _primary_term: 2 })
      expect(described_class.new.get_claims).to(eq(nil))
    end

    it 'runs through get_claims in response failure' do
      ClaimReview.stub(:existing_ids).with(['123'], described_class.service).and_return([])
      RestClient.stub(:post).with(anything, anything, anything).and_return({})
      expect(described_class.new.get_claims).to(eq(nil))
    end

    it 'parses a raw_claim' do
      raw = JSON.parse(File.read('spec/fixtures/gesis_claims_raw.json'))
      parsed_claim = described_class.new.parse_raw_claim(raw)
      expect(parsed_claim.class).to(eq(Hash))
      ClaimReview.mandatory_fields.each do |field|
        expect(Hashie::Mash[parsed_claim][field].nil?).to(eq(false))
      end
    end

    it 'rescues from id_from_raw_claim' do
      expect(described_class.new.id_from_raw_claim({})).to(eq('d41d8cd98f00b204e9800998ecf8427e'))
    end

    it 'rescues from author_from_raw_claim' do
      expect(described_class.new.author_from_raw_claim({})).to(eq(nil))
    end

    it 'rescues from created_at_from_raw_claim' do
      expect(described_class.new.created_at_from_raw_claim({})).to(eq(nil))
    end

    it 'rescues from author_link_from_raw_claim' do
      expect(described_class.new.author_link_from_raw_claim({})).to(eq(nil))
    end

    it 'rescues from claim_headline_from_raw_claim' do
      expect(described_class.new.claim_headline_from_raw_claim({})).to(eq(nil))
    end

    it 'rescues from claim_result_from_raw_claim' do
      expect(described_class.new.claim_result_from_raw_claim({})).to(eq(nil))
    end

    it 'rescues from claim_result_score_from_raw_claim' do
      expect(described_class.new.claim_result_score_from_raw_claim({})).to(eq(nil))
    end

    it 'rescues from claim_url_from_raw_claim' do
      expect(described_class.new.claim_url_from_raw_claim({})).to(eq(nil))
    end
  end
end
