# frozen_string_literal: true

describe DataCommons do
  describe 'instance' do
    it 'parses a raw_claim' do
      raw = JSON.parse(File.read('spec/fixtures/data_commons_raw.json'))
      parsed_claim = described_class.new.parse_raw_claim(raw)
      expect(parsed_claim.class).to(eq(Hash))
      ClaimReview.mandatory_fields.each do |field|
        expect(Hashie::Mash[parsed_claim][field].nil?).to(eq(false))
      end
    end
  end
end
