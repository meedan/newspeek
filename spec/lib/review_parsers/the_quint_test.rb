# frozen_string_literal: true

describe TheQuint do
  describe 'instance' do
    it 'has a hostname' do
      expect(described_class.new.hostname).to(eq('https://www.thequint.com'))
    end

    it 'has a fact_list_path' do
      expect(described_class.new.fact_list_path(1)).to(eq('/news/webqoof/1'))
    end

    it 'parses a raw_claim' do
      raw = JSON.parse(File.read('spec/fixtures/the_quint_raw.json'))
      parsed_claim = described_class.new.parse_raw_claim(raw)
      expect(parsed_claim.class).to(eq(Hash))
      ClaimReview.mandatory_fields.each do |field|
        expect(Hashie::Mash[parsed_claim][field].nil?).to(eq(false))
      end
    end

    it 'walks through get_claims' do
      described_class.any_instance.stub(:get_new_claims_for_page).with(1).and_return([{}])
      described_class.any_instance.stub(:get_new_claims_for_page).with(2).and_return([])
      ClaimReview.stub(:existing_urls).with(anything, described_class.service).and_return([])
      expect(described_class.new.get_claims).to(eq(nil))
    end

    it 'walks through get_claims_for_page' do
      RestClient.stub(:get).with(anything).and_return(File.read('spec/fixtures/the_quint_page.html'))
      ClaimReview.stub(:existing_urls).with(anything, described_class.service).and_return([])
      expect(described_class.new.get_new_claims_for_page.class).to(eq(Array))
    end

    it 'rescues from author_from_raw_claim' do
      expect(described_class.new.author_from_raw_claim({})).to(eq(nil))
    end

    it 'rescues from author_link_from_raw_claim' do
      expect(described_class.new.author_link_from_raw_claim({})).to(eq(nil))
    end

    it 'rescues from claim_result_from_raw_claim' do
      expect(described_class.new.claim_result_from_raw_claim({})).to(eq(nil))
    end

    it 'rescues from claim_result_score_from_raw_claim' do
      expect(described_class.new.claim_result_score_from_raw_claim({})).to(eq(nil))
    end
  end
end
