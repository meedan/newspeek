SimpleCov.command_name "test:integration"
describe 'integration test with ElasticSearch' do#, integration: true do
  include Rack::Test::Methods

  def app
    Site
  end
  before do
    @storage_results ||= {}
    WebMock.allow_net_connect!
    ClaimReviewParser.enabled_subclasses.each do |subclass|
      raw = JSON.parse(File.read("spec/fixtures/#{subclass.service}_raw.json"))
      raw['page'] = Nokogiri.parse(raw['page']) if raw['page']
      parsed_claim_review = subclass.new.parse_raw_claim_review(raw)
      @storage_results[subclass] = subclass.new("2000-01-01", true).process_claim_reviews([parsed_claim_review])
    end
  end

  after do
    WebMock.disable_net_connect!
  end
    
  ClaimReviewParser.enabled_subclasses.each do |subclass|
    it "ensures #{subclass}'s response looks as if it were saved" do
      expect(@storage_results[subclass].class).to(eq(Array))
      expect(@storage_results[subclass][0].class).to(eq(Hash))
    end

    it "ensures #{subclass}'s response has the mandatory fields" do
      expect(@storage_results[subclass].first.values_at(*(@storage_results[subclass].first.keys-[:raw_claim_review])).collect(&:class).uniq-[NilClass, String, Float, Time, Integer]).to(eq([]))
    end

    it "ensures access of #{subclass} via ClaimReview#existing_ids" do
      ids = @storage_results[subclass].collect{|x| x[:id]}
      expect(ClaimReview.existing_ids(ids, subclass.service).class).to(eq(Array))
      expect(ClaimReview.existing_ids(ids, subclass.service).count).to(eq(1))
    end

    it "ensures access of #{subclass} via ClaimReview#existing_urls" do
      urls = @storage_results[subclass].collect{|x| x[:claim_review_url]}
      expect(ClaimReview.existing_urls(urls, subclass.service).class).to(eq(Array))
      expect(ClaimReview.existing_urls(urls, subclass.service).count).to(eq(1))
    end


    it "ensures count of #{subclass} via ClaimReview#get_count_for_service" do
      expect(ClaimReview.get_count_for_service(subclass.service) > 0).to(eq(true))
    end

    it "ensures access of #{subclass} via Site-layer" do
      response = get "/claim_reviews", "service=#{subclass.service}"
      # begin
      gg = JSON.parse(response.body)
      gz = @storage_results[subclass]
        expect(gg[0]["url"]).to(eq(gz[0][:claim_review_url]))
        puts gg.inspect
        puts gz.inspect
        
      # rescue
      #   binding.pry
      # end
    end
    
    it "ensures access of #{subclass} via API-layer" do
      # begin
        expect(API.claim_reviews(service: subclass.service.to_s)[0][:url]).to(eq(@storage_results[subclass][0][:claim_review_url]))
      # rescue
      #   binding.pry
      # end
    end

    it "ensures access of #{subclass} via Search-layer" do
      # begin
        expect(ClaimReview.search(service: subclass.service.to_s)[0][:url]).to(eq(@storage_results[subclass][0][:claim_review_url]))
      # rescue
      #   binding.pry
      # end
    end

    it "ensures access of #{subclass} via Search-layer" do
      language = Language.get_reliable_language(@storage_results[subclass][0][:claim_review_headline])
      if language
        expect(ClaimReview.search(language: language)[0][:inLanguage]).to(eq(language))
      end
    end

    it "ensures deletion of #{subclass} object" do
      response = ClaimReview.delete_by_service(subclass.service.to_s)
      expect(response["failures"]).to(eq([]))
    end
  end
end
