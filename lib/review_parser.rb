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

  def self.run(service)
    parsers[service].new.get_claims
  end

  def process_claims(claims)
    self.class.store_to_db(
      claims, self.class.service
    )
    claims
  end

  def finished_iterating?(claims)
    oldest_time = claims.map { |x| x[:created_at] }.min
    claims.empty? || (!@cursor_back_to_date.nil? && oldest_time > @cursor_back_to_date)
  end

  def parse_raw_claims(raw_claims)
    if @run_in_parallel
      Parallel.map(parse_raw_claims, in_processes: 5, progress: "Downloading #{self.class} Corpus") do |raw_claim|
        parse_raw_claim(raw_claim)
      end.compact
    else
      raw_claims.map { |raw_claim| parse_raw_claim(raw_claim) }
    end
  end
end
