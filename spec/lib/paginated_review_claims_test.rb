# frozen_string_literal: true

class StubReview < ReviewParser
  include PaginatedReviewClaims
  def hostname
    'http://examplejson.com'
  end

  def fact_list_path(page = 1)
    "/get?page=#{page}"
  end

  def url_extraction_search
    'a'
  end
end
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

  def parse_raw_claim(raw_claim)
    raw_claim
  end
end

describe PaginatedReviewClaims do
  before do
    stub_request(:get, 'http://examplejson.com:9200/claim_reviews/_search')
      .with(
        body: /.*/,
        headers: {
          Accept: '*/*',
          "Accept-Encoding": 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          "Content-Type": 'application/json',
          "User-Agent": /.*/
        }
      )
      .to_return(status: 200, body: '{}', headers: {})
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
    stub_request(:get, 'http://examplejson.com/get?page=1')
      .with(
        headers: {
          Accept: '*/*',
          "Accept-Encoding": 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          Host: 'examplejson.com',
          "User-Agent": /.*/
        }
      )
      .to_return(status: 200, body: '{"page": [1]}', headers: {})
  end

  describe 'instance' do
    it 'rescues failed get_url' do
      RestClient.stub(:get).with(StubReviewJSON.new.hostname).and_raise(RestClient::NotFound)
      expect(StubReviewJSON.new.get_url(StubReviewJSON.new.hostname)).to(eq(nil))
    end

    it 'expects get_url' do
      expect(StubReviewJSON.new.get_url(StubReviewJSON.new.hostname).class).to(eq(RestClient::Response))
    end

    it 'expects html parsed_fact_list_page' do
      expect(StubReview.new.parsed_fact_list_page(1).class).to(eq(Nokogiri::XML::Document))
    end

    it 'expects json parsed_fact_list_page' do
      expect(StubReviewJSON.new.parsed_fact_list_page(1)).to(eq({ 'page' => [1] }))
    end

    it 'expects json get_fact_page_urls' do
      expect(StubReviewJSON.new.get_fact_page_urls(1)).to(eq([1]))
    end

    it 'expects empty get_fact_page_urls' do
      StubReviewJSON.any_instance.stub(:parsed_fact_list_page).with(1).and_return(nil)
      expect(StubReviewJSON.new.get_fact_page_urls(1)).to(eq([]))
    end

    it 'expects html parsed_fact_list_page' do
      expect(StubReview.new.get_fact_page_urls(1).class).to(eq(Array))
    end

    it 'expects parsed_fact_page' do
      response = StubReviewJSON.new.parsed_fact_page(StubReviewJSON.new.hostname)
      expect(response[0]).to(eq('http://examplejson.com'))
      expect(response[1].class).to(eq(Hashie::Mash))
      expect(response[1].keys.sort).to(eq(%w[page url]))
    end

    it 'expects novel get_new_fact_page_urls' do
      allow(ClaimReview).to(receive(:client).and_return(double('client')))
      ClaimReview.client.stub(:search).with(anything).and_return({ 'hits' => { 'hits' => [] } })
      response = StubReviewJSON.new.get_new_fact_page_urls(1)
      expect(response[0]).to(eq(1))
    end

    it 'expects saved get_new_fact_page_urls' do
      allow(ClaimReview).to(receive(:client).and_return(double('client')))
      ClaimReview.client.stub(:search).with(anything).and_return({ 'hits' => { 'hits' => [{ '_source' => { claim_url: 1 } }] } })
      response = StubReviewJSON.new.get_new_fact_page_urls(1)
      expect(response).to(eq([1]))
    end

    it 'expects empty get_claims' do
      allow(ClaimReview).to(receive(:client).and_return(double('client')))
      ClaimReview.client.stub(:search).with(anything).and_return({ 'hits' => { 'hits' => [{ '_source' => { claim_url: 1 } }] } })
      response = StubReviewJSON.new.get_claims
      expect(response).to(eq(nil))
    end

    it 'iterates on get_claims' do
      StubReviewJSON.any_instance.stub(:store_claims_for_page).with(1).and_return([{ 'created_at': Time.now - 7 * 24 * 24 * 60 }])
      StubReviewJSON.any_instance.stub(:store_claims_for_page).with(2).and_return([])
      response = StubReviewJSON.new.get_claims
      expect(response).to(eq(nil))
    end

    it 'expects get_parsed_fact_pages_from_urls' do
      allow(ClaimReview).to(receive(:client).and_return(double('client')))
      ClaimReview.client.stub(:search).with(anything).and_return({ 'hits' => { 'hits' => [{ '_source' => { claim_url: 1 } }] } })
      response = StubReviewJSON.new.get_parsed_fact_pages_from_urls([1])
      expect(response).to(eq([]))
    end

    it 'expects get_parsed_fact_pages_from_urls' do
      allow(ClaimReview).to(receive(:client).and_return(double('client')))
      ClaimReview.client.stub(:search).with(anything).and_return({ 'hits' => { 'hits' => [{ '_source' => { claim_url: 1 } }] } })
      response = StubReview.new.get_parsed_fact_pages_from_urls([1])
      expect(response).to(eq([]))
    end
  end
end
