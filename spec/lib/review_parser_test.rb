# frozen_string_literal: true

describe ReviewParser do
  describe 'instance' do
    it 'expects forcefully-emptied get_existing_urls' do
      rp = described_class.new(Time.now - 60 * 60 * 24)
      expect(rp.get_existing_urls(['123'])).to(eq([]))
    end

    it 'expects default attributes' do
      rp = described_class.new
      expect(rp.send('fact_list_page_parser')).to(eq('html'))
      expect(rp.run_in_parallel).to(eq(true))
    end

    it 'expects to be able to parse_raw_claims in parallel' do
      rp = AFP.new
      AFP.any_instance.stub(:parse_raw_claim).with({}).and_return({})
      expect(rp.parse_raw_claims([{}, {}])).to(eq([{}, {}]))
    end
  end

  describe 'class' do
    it 'expects service symbol' do
      expect(described_class.service).to(eq(:review_parser))
    end

    it 'expects parsers map' do
      expect(described_class.parsers.keys.map(&:class).uniq).to(eq([String]))
      expect(!described_class.parsers.values.map(&:superclass).uniq.empty?).to(eq(true))
    end

    it 'expects to be able to run' do
      AFP.any_instance.stub(:get_claims).and_return('stubbed')
      expect(described_class.run('afp')).to(eq('stubbed'))
    end
  end
end
