# frozen_string_literal: true
class StubReviewJSON < ReviewParser
  include PaginatedReviewClaims
  def initialize
    @fact_list_page_parser = 'json'
  end

  def hostname
    'http://examplejson.com'
  end

  def fact_list_path(page = 1)
    "/get?page=#{page}"
  end

  def url_extractor(response)
    response['page']
  end

  def parse_raw_claim_review(raw_claim_review)
    raw_claim_review
  end
end

describe ReviewParser do
  before do
    stub_request(:get, 'http://examplejson.com/')
      .with(
        headers: {
          Accept: '*/*',
          "Accept-Encoding": 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          Host: 'examplejson.com',
          "User-Agent": /.*/
        }
      )
      .to_return(status: 200, body: '{"blah": 1}', headers: {})
  end

  describe 'instance' do
    it 'rescues failed get_url' do
      RestClient.stub(:get).with(StubReviewJSON.new.hostname).and_raise(RestClient::NotFound)
      expect(StubReviewJSON.new.get_url(StubReviewJSON.new.hostname)).to(eq(nil))
    end

    it 'expects get_url' do
      expect(StubReviewJSON.new.get_url(StubReviewJSON.new.hostname).class).to(eq(RestClient::Response))
    end

    it 'expects forcefully-emptied get_existing_urls' do
      rp = described_class.new(Time.now - 60 * 60 * 24)
      expect(rp.get_existing_urls(['123'])).to(eq([]))
    end

    it 'expects default attributes' do
      rp = described_class.new
      expect(rp.send('fact_list_page_parser')).to(eq('html'))
      expect(rp.run_in_parallel).to(eq(true))
    end

    it 'expects to be able to parse_raw_claim_reviews in parallel' do
      rp = AFP.new
      AFP.any_instance.stub(:parse_raw_claim_review).with({}).and_return({})
      expect(rp.parse_raw_claim_reviews([{}, {}])).to(eq([{}, {}]))
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
      AFP.any_instance.stub(:get_claim_reviews).and_return('stubbed')
      expect(described_class.run('afp')).to(eq('stubbed'))
    end
  end
end
