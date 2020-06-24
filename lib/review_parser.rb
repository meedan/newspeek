#Eventually all subclasses here will need standardization about
class ReviewParser
  attr_accessor :fact_list_page_parser, :run_in_parallel
  def initialize
    @fact_list_page_parser = "html"
    @run_in_parallel = true
    @logger = Logger.new("log/"+self.class.service.to_s+'_claim_review_parser.log', 0, 100 * 1024 * 1024)
  end

  def self.service
    self.to_s.underscore.to_sym
  end
  def self.parsers
    Hashie::Mash[
      Hash[ReviewParser.subclasses.collect{|sc| 
        [sc.service, sc]
      }]
    ]
  end
  
  def self.store_to_db(claims, service)
    claims.each do |parsed_claim|
      ClaimReview.store_claim(Hashie::Mash[parsed_claim], service)
    end
  end

  def self.run(service)
    self.store_to_db(
      self.parsers[service].new.get_claims, service
    )
  end
end