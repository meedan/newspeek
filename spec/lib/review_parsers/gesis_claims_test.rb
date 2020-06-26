# frozen_string_literal: true

describe GESISClaims do
  describe 'instance' do
    it 'walks through the get_request' do
      RestClient.stub(:post).with(anything(), anything(), anything()).and_return({})
      expect(described_class.new.get_fact("123")).to(eq(nil))
    end

    it 'parses the in-repo dataset' do
      CSV.stub(:read).with(described_class.dataset_path).and_return([["123"]])
      ClaimReview.stub(:existing_ids).with(["123"], described_class.service).and_return([])
      RestClient.stub(:post).with(anything(), anything(), anything()).and_return({})
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
