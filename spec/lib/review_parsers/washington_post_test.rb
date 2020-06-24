describe WashingtonPost do
  describe "instance" do
    it "parses list_pages in json" do
      expect(WashingtonPost.new.fact_list_page_parser).to eq("json")
    end
    it "has a hostname" do
      expect(WashingtonPost.new.hostname).to eq("https://www.washingtonpost.com")
    end

    it "has a fact_list_path" do
      expect(WashingtonPost.new.fact_list_path(1)).to eq("/pb/api/v2/render/feature/section/story-list?addtl_config=blog-front&content_origin=content-api-query&size=10&from=0&primary_node=/politics/fact-checker")
    end

    it "has a url_extractor" do
      expect(WashingtonPost.new.url_extractor({"rendering" => "<div class='story-headline'><h2><a href='/blah'>wow</a></h2></div>"})).to eq(["https://www.washingtonpost.com/blah"])
    end
    
    it "parses a raw_claim" do
      raw = JSON.parse(File.read("spec/fixtures/washington_post_raw.json"))
      raw["page"] = Nokogiri.parse(raw["page"])
      parsed_claim = WashingtonPost.new.parse_raw_claim(raw)
      expect(parsed_claim.class).to eq(Hash)
      ClaimReview.mandatory_fields.each do |field|
        expect(Hashie::Mash[parsed_claim][field].nil?).to eq(false)
      end
    end
  end
end