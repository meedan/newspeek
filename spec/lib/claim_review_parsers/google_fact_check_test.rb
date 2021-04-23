# frozen_string_literal: true

describe GoogleFactCheck do
  describe 'instance' do
    it 'has default_queries' do
      expect(described_class.new.default_queries.class).to(eq(Array))
    end

    it 'has a host' do
      expect(described_class.new.host).to(eq('https://factchecktools.googleapis.com'))
    end

    it 'has a path' do
      expect(described_class.new.path).to(eq('/v1alpha1/claims:search'))
    end

    it 'parses a raw_claim_review' do
      raw = JSON.parse(File.read('spec/fixtures/google_fact_check_raw.json'))
      parsed_claim = described_class.new.parse_raw_claim_review(raw)
      expect(parsed_claim.class).to(eq(Hash))
      ClaimReview.mandatory_fields.each do |field|
        expect(QuietHashie[parsed_claim][field].nil?).to(eq(false))
      end
    end

    it 'parses a raw_claim with bad time' do
      raw = JSON.parse(File.read('spec/fixtures/google_fact_check_raw.json'))
      raw['claimReview'][0]['reviewDate'] = nil
      raw['claimDate'] = nil
      parsed_claim = described_class.new.parse_raw_claim_review(raw)
      expect(parsed_claim.class).to(eq(Hash))
      (ClaimReview.mandatory_fields - ['created_at']).each do |field|
        expect(QuietHashie[parsed_claim][field].nil?).to(eq(false))
      end
    end

    it 'runs snowball_publishers_from_query' do
      raw = JSON.parse(File.read('spec/fixtures/google_fact_check_raw.json'))
      described_class.any_instance.stub(:get_all_for_query).with('election').and_return([raw])
      expect(described_class.new.snowball_publishers_from_query.class).to(eq(Array))
    end

    it 'runs get_all_for_publisher' do
      RestClient.stub(:get).with(anything).and_return(RestClient::Response.new('{}'))
      described_class.any_instance.stub(:store_claim_reviews_for_publisher_and_offset).with('foo', 0).and_return([{}])
      described_class.any_instance.stub(:store_claim_reviews_for_publisher_and_offset).with('foo', 100).and_return([])
      expect(described_class.new.get_all_for_publisher('foo')).to(eq(nil))
    end

    it 'runs get_all_for_query' do
      described_class.any_instance.stub(:get_query).with('foo').and_return({ 'claims' => [{}] })
      described_class.any_instance.stub(:get_query).with('foo', 100).and_return({ 'claims' => [{}] })
      described_class.any_instance.stub(:get_query).with('foo', 200).and_return({ 'claims' => [] })
      expect(described_class.new.get_all_for_query('foo')).to(eq([{}, {}]))
    end

    it 'runs get_all_for_query' do
      RestClient.stub(:get).with(anything).and_return(RestClient::Response.new('{}'))
      expect(described_class.new.get_all_for_query('foo')).to(eq([]))
    end

    it 'runs get_publisher' do
      RestClient.stub(:get).with(anything).and_return(RestClient::Response.new('{}'))
      expect(described_class.new.get_publisher('foo')).to(eq({}))
    end

    it 'runs get with unavailable error' do
      RestClient.stub(:get).with(anything).and_raise(RestClient::ServiceUnavailable)
      expect(described_class.new.get('foo', {})).to(eq({}))
    end

    it 'runs get with forbidden error' do
      RestClient.stub(:get).with(anything).and_raise(RestClient::Forbidden)
      expect(described_class.new.get('foo', {})).to(eq({}))
    end

    it 'runs get with bad request error' do
      RestClient.stub(:get).with(anything).and_raise(RestClient::BadRequest)
      expect(described_class.new.get('foo', {})).to(eq({}))
    end

    it 'runs get_new_from_publisher' do
      ClaimReview.stub(:existing_urls).with(anything, anything).and_return([])
      raw = JSON.parse(File.read('spec/fixtures/google_fact_check_raw.json'))
      described_class.any_instance.stub(:get_publisher).with('foo', 0).and_return({ 'claims' => [raw] })
      result = described_class.new.get_new_from_publisher('foo', 0)
      expect(result.class).to(eq(Array))
      expect(result.length).to(eq(1))
      expect(result.first.class).to(eq(Hash))
    end

    it 'rescues from created_at_from_raw_claim_review' do
      expect(described_class.new.created_at_from_raw_claim_review({})).to(eq(nil))
    end

    it 'rescues from claim_url_from_raw_claim_review' do
      expect(described_class.new.claim_url_from_raw_claim_review({})).to(eq(nil))
    end

    it 'runs store_claim_reviews_for_publisher_and_offset' do
      raw = JSON.parse(File.read('spec/fixtures/google_fact_check_raw.json'))
      described_class.any_instance.stub(:get_new_from_publisher).with('foo', 0).and_return([raw])
      ClaimReviewParser.any_instance.stub(:store_to_db).with(anything, anything).and_return([])
      result = described_class.new.store_claim_reviews_for_publisher_and_offset('foo', 0)
      expect(result.class).to(eq(Array))
      expect(result.length).to(eq(1))
      expect(result.first.class).to(eq(Hash))
    end

    it 'runs snowball_publishers_from_queries' do
      raw = JSON.parse(File.read('spec/fixtures/google_fact_check_raw.json'))
      described_class.any_instance.stub(:get_all_for_query).with('election').and_return([raw])
      expect(described_class.new.snowball_publishers_from_queries(['election']).class).to(eq(Array))
    end

    it 'runs snowball_claim_reviews_from_publishers' do
      RestClient.stub(:get).with(anything).and_return(RestClient::Response.new('{}'))
      described_class.any_instance.stub(:store_claim_reviews_for_publisher_and_offset).with('foo', 0).and_return([{}])
      described_class.any_instance.stub(:store_claim_reviews_for_publisher_and_offset).with('foo', 100).and_return([])
      expect(described_class.new.snowball_claim_reviews_from_publishers(['foo'])).to(eq([nil]))
    end

    it 'runs get_claim_reviews' do
      RestClient.stub(:get).with(anything).and_return(RestClient::Response.new('{}'))
      described_class.any_instance.stub(:service_key_is_needed?).and_return(false)
      described_class.any_instance.stub(:store_claim_reviews_for_publisher_and_offset).with(anything, 0).and_return([{}])
      described_class.any_instance.stub(:store_claim_reviews_for_publisher_and_offset).with(anything, 100).and_return([])
      raw = JSON.parse(File.read('spec/fixtures/google_fact_check_raw.json'))
      described_class.any_instance.stub(:get_all_for_query).with(anything).and_return([raw])
      expect(described_class.new.get_claim_reviews).to(eq([nil]))
    end
  end
end
