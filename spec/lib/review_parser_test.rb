describe ReviewParser do
  describe 'instance' do
    it 'expects default attributes' do
      rp = ReviewParser.new
      expect(rp.send("fact_list_page_parser")).to eq("html")
      expect(rp.run_in_parallel).to eq(true)
    end
  end

  describe 'class' do
    it 'expects service symbol' do
      expect(ReviewParser.service).to eq(:review_parser)
    end
    
    it 'expects parsers map' do
      expect(ReviewParser.parsers.keys.collect(&:class).uniq).to eq([String])
      expect(ReviewParser.parsers.values.collect(&:superclass).uniq).to eq([ReviewParser, AFP])
    end
  end
end