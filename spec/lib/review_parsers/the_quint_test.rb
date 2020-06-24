describe TheQuint do
  describe "instance" do
    it "has a hostname" do
      expect(TheQuint.new.hostname).to eq("https://www.thequint.com")
    end
    
    it "has a fact_list_path" do
      expect(TheQuint.new.fact_list_path(1)).to eq("/news/webqoof/1")
    end

    it "parses a raw_claim" do
      raw = JSON.parse(File.read("spec/fixtures/the_quint_raw.json"))
      parsed_claim = TheQuint.new.parse_raw_claim(raw)
      expect(parsed_claim.class).to eq(Hash)
      ClaimReview.mandatory_fields.each do |field|
        expect(Hashie::Mash[parsed_claim][field].nil?).to eq(false)
      end
    end
  end
end