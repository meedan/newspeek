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

  def self.store_to_db(claims, service)
    claims.each do |parsed_claim|
      ClaimReview.store_claim(Hashie::Mash[parsed_claim], service)
    end
  end

  def self.run(service, cursor_back_to_date = nil)
    parsers[service].new(cursor_back_to_date).get_claims
  end

  def get_existing_urls(urls)
    existing_urls = if @cursor_back_to_date
                      # force checking every URL directly instead of bypassing quietly...
                      []
                    else
                      ClaimReview.existing_urls(urls, self.class.service)
                    end
    existing_urls
  end

  def process_claims(claims)
    self.class.store_to_db(
      claims, self.class.service
    )
    claims
  end

  def finished_iterating?(claims)
    times = claims.map { |x| Hashie::Mash[x][:created_at] }.compact
    oldest_time = if times.empty?
                    @cursor_back_to_date
                  else
                    times.min
                  end
    claims.empty? || (!@cursor_back_to_date.nil? && oldest_time < @cursor_back_to_date)
  end

  def parse_raw_claims(raw_claims)
    Parallel.map(raw_claims, in_processes: 5, progress: "Downloading #{self.class} Corpus") do |raw_claim|
      parse_raw_claim(raw_claim)
    end.compact
  end
end
