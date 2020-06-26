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

    it 'parses the in-repo dataset' do
      single_case = JSON.parse(File.read('spec/fixtures/data_commons_raw.json'))
      File.stub(:read).with(described_class.dataset_path).and_return({ 'dataFeedElement' => [single_case] }.to_json)
      ClaimReview.stub(:existing_urls).with([single_case['item'][0]['url']], described_class.service).and_return([])
      expect(described_class.new.get_claims).to(eq(nil))
    end

    it 'parses non-empty parse_datacommons_rating' do
      expect(described_class.new.parse_datacommons_rating({ 'reviewRating' => { 'bestRating' => 10, 'worstRating' => 0, 'ratingValue' => 5 } })).to(eq(0.5))
    end

    it 'parses partially-empty parse_datacommons_rating' do
      expect(described_class.new.parse_datacommons_rating({ 'reviewRating' => { 'ratingValue' => 5 } })).to(eq(5))
    end

    it 'rescues from service_id_from_raw_claim' do
      expect(described_class.new.service_id_from_raw_claim({})).to(eq(''))
    end

    it 'rescues from author_from_raw_claim' do
      expect(described_class.new.author_from_raw_claim({})).to(eq(nil))
    end

    it 'rescues from created_at_from_raw_claim' do
      expect(described_class.new.created_at_from_raw_claim({})).to(eq(nil))
    end

    it 'rescues from author_from_raw_claim' do
      expect(described_class.new.author_from_raw_claim({})).to(eq(nil))
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

    it 'rescues from claim_url_from_raw_claim' do
      expect(described_class.new.claim_url_from_raw_claim({})).to(eq(nil))
    end
  end
end
