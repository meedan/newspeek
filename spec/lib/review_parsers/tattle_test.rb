# frozen_string_literal: true

describe Tattle do
  describe 'instance' do
    it 'parses a raw_claim' do
      raw = JSON.parse(File.read('spec/fixtures/tattle_raw.json'))
      parsed_claim = described_class.new.parse_raw_claim(raw)
      expect(parsed_claim.class).to(eq(Hash))
      ClaimReview.mandatory_fields.each do |field|
        expect(Hashie::Mash[parsed_claim][field].nil?).to(eq(false))
      end
    end

    it 'parses the in-repo dataset' do
      single_case = JSON.parse(File.read('spec/fixtures/tattle_raw.json'))
      File.stub(:read).with(described_class.dataset_path).and_return([single_case].to_json)
      ClaimReview.stub(:existing_urls).with([single_case['Post URL']], described_class.service).and_return([])
      expect(described_class.new.get_claims).to(eq(nil))
    end

    it 'parses the in-repo dataset with no content' do
      single_case = JSON.parse(File.read('spec/fixtures/tattle_raw.json'))
      single_case['Docs'] = []
      File.stub(:read).with(described_class.dataset_path).and_return([single_case].to_json)
      ClaimReview.stub(:existing_urls).with([single_case['Post URL']], described_class.service).and_return([])
      expect(described_class.new.get_claims).to(eq(nil))
    end
  end
end
