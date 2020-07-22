# frozen_string_literal: true

# Eventually all subclasses here will need standardization about
class ReviewParser
  attr_accessor :fact_list_page_parser, :run_in_parallel

  def initialize(cursor_back_to_date = nil)
    @fact_list_page_parser = 'html'
    @run_in_parallel = true
    @logger = Logger.new(STDOUT)
    @current_claims = []
    @cursor_back_to_date = cursor_back_to_date
  end

  def self.service
    to_s.underscore.to_sym
  end

  def self.parsers
    Hashie::Mash[
      Hash[ReviewParser.subclasses.map do |sc|
        [sc.service, sc]
      end]
    ]
  end

  def self.store_to_db(claim_reviews, service)
    claim_reviews.each do |parsed_claim_review|
      ClaimReview.store_claim_review(Hashie::Mash[parsed_claim_review], service)
    end
  end

  def self.run(service, cursor_back_to_date = nil)
    parsers[service].new(cursor_back_to_date).get_claim_reviews
  end

  def make_request
    retry_count = 0
    begin
      yield
    rescue RestClient::BadGateway, RestClient::NotFound, SocketError, Errno::ETIMEDOUT => e
      if retry_count < 3
        retry_count += 1
        sleep(1)
        retry
      else
        Error.log(e)
        return nil
      end
    end
  end

  def post_url(url, body)
    make_request do
      response = RestClient.post(
        url, body
      )
    end
  end

  def get_url(url)
    make_request do
      response = RestClient.get(
        url
      )
    end
  end

  def get_existing_urls(urls)
    if @cursor_back_to_date
      # force checking every URL directly instead of bypassing quietly...
      []
    else
      ClaimReview.existing_urls(urls, self.class.service)
    end
  end

  def process_claim_reviews(claim_reviews)
    self.class.store_to_db(
      claim_reviews, self.class.service
    )
    claim_reviews
  end

  def finished_iterating?(claim_reviews)
    times = claim_reviews.map { |x| Hashie::Mash[x][:created_at] }.compact
    oldest_time = if times.empty?
                    @cursor_back_to_date
                  else
                    times.min
                  end
    claim_reviews.empty? || (!@cursor_back_to_date.nil? && oldest_time < @cursor_back_to_date)
  end

  def parse_raw_claim_reviews(raw_claim_reviews)
    Parallel.map(raw_claim_reviews, in_processes: 5, progress: "Downloading #{self.class} Corpus") do |raw_claim_review|
      parse_raw_claim_review(raw_claim_review)
    end.compact
  end
  
  def extract_ld_json_script_block(page, index, search_path="script")
    script_block = page && page.search(search_path).select{|x| x.attributes["type"] && x.attributes["type"].value == "application/ld+json"}[index]
    script_block && JSON.parse(script_block.text)
  end
end
