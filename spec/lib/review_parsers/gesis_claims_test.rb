# frozen_string_literal: true

describe GESISClaims do
  describe 'instance' do
    it 'parses a raw_claim' do
      raw = JSON.parse(File.read('spec/fixtures/gesis_claims_raw.json'))
      parsed_claim = GESISClaims.new.parse_raw_claim(raw)
      expect(parsed_claim.class).to eq(Hash)
      ClaimReview.mandatory_fields.each do |field|
        expect(Hashie::Mash[parsed_claim][field].nil?).to eq(false)
      end
    end
  end
end
