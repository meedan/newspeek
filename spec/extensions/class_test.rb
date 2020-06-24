describe Class do
  describe "instance" do
    it "should list subclasses" do
      expect(ReviewParser.subclasses.class).to eq(Array)
    end

    it "should list nonempty subclasses for ReviewParser" do
      expect(ReviewParser.subclasses.length == 0).to eq(false)
    end

    it "should list empty subclasses for API" do
      expect(API.subclasses).to eq([])
    end
  end
end