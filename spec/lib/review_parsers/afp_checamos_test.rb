describe AFPChecamos do
  describe "instance" do
    it "has a hostname" do
      expect(AFPChecamos.new.hostname).to eq("https://checamos.afp.com")
    end

    it "has a fact_list_path" do
      expect(AFPChecamos.new.fact_list_path(1)).to eq("/?page=0")
    end

    it "has a url_extraction_search" do
      expect(AFPChecamos.new.url_extraction_search).to eq("div.view-content div.content-teaser h2.content-title a")
    end
    
    it "extracts a url" do
      expect(AFPChecamos.new.url_extractor(Nokogiri.parse("<a href='/blah'>wow</a>").search("a")[0])).to eq("https://checamos.afp.com/blah")
    end
    
    it "parses a raw_claim" do
      raw = JSON.parse(File.read("spec/fixtures/afp_checamos_raw.json"))
      raw["page"] = Nokogiri.parse(raw["page"])
      parsed_claim = AFPChecamos.new.parse_raw_claim(raw)
      expect(parsed_claim.class).to eq(Hash)
      ClaimReview.mandatory_fields.each do |field|
        expect(Hashie::Mash[parsed_claim][field].nil?).to eq(false)
      end
    end
  end
end
