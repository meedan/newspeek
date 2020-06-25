# frozen_string_literal: true

describe BoomLive do
  describe 'instance' do
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
