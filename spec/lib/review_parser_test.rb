# frozen_string_literal: true

describe ReviewParser do
  describe 'instance' do
    it 'expects default attributes' do
      rp = described_class.new
      expect(rp.send('fact_list_page_parser')).to(eq('html'))
      expect(rp.run_in_parallel).to(eq(true))
    end
  end

  describe 'class' do
    it 'expects service symbol' do
      expect(described_class.service).to(eq(:review_parser))
    end

    it 'expects parsers map' do
      expect(described_class.parsers.keys.map(&:class).uniq).to(eq([String]))
      expect(described_class.parsers.values.map(&:superclass).uniq).to(eq([described_class, AFP]))
    end
  end
end
