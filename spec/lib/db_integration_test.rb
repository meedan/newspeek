describe 'integration test with ElasticSearch' do#, integration: true do
  before do
    WebMock.allow_net_connect!
  end

  after do
    WebMock.disable_net_connect!
  end

  (ClaimReviewParser.subclasses-[StubReviewJSON]).each do |subclass|
    it "ensures #{subclass} saves ES-storable objects, and yields those objects" do 
      raw = JSON.parse(File.read("spec/fixtures/#{subclass.service}_raw.json"))
      raw['page'] = Nokogiri.parse(raw['page']) if raw['page']
      parsed_claim_review = subclass.new.parse_raw_claim_review(raw)
      storage_result = subclass.new("2000-01-01", true).process_claim_reviews([parsed_claim_review])
      expect(storage_result.first.values_at(*(storage_result.first.keys-[:raw_claim_review])).collect(&:class).uniq-[NilClass, String, Float, Time, Integer]).to(eq([]))
      expect(ClaimReview.existing_ids(storage_result.collect{|x| x[:id]}, subclass.service).class).to(eq(Array))
      expect(ClaimReview.existing_ids(storage_result.collect{|x| x[:id]}, subclass.service).count).to(eq(1))
      expect(ClaimReview.existing_urls(storage_result.collect{|x| x[:claim_review_url]}, subclass.service).class).to(eq(Array))
      expect(ClaimReview.existing_urls(storage_result.collect{|x| x[:claim_review_url]}, subclass.service).count).to(eq(1))
      expect(ClaimReview.get_count_for_service(subclass.service)['value'] > 0).to(eq(true))
    end
  end
end
