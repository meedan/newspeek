# frozen_string_literal: true

class WashingtonPost < ReviewParser
  include PaginatedReviewClaims
  def initialize(cursor_back_to_date = nil)
    super(cursor_back_to_date)
    @fact_list_page_parser = 'json'
  end

  def hostname
    'https://www.washingtonpost.com'
  end

  def fact_list_path(page = 1)
    "/pb/api/v2/render/feature/section/story-list?addtl_config=blog-front&content_origin=content-api-query&size=10&from=#{10 * (page - 1)}&primary_node=/politics/fact-checker"
  end

  def url_extractor(json_response)
    Nokogiri.parse('<html>' + json_response['rendering'] + '</html>').search('div.story-headline h2 a').collect { |x| hostname + x.attributes['href'].value }
  end

  def parse_raw_claim(raw_claim)
    pinocchios = raw_claim['page'].search('h3').collect(&:text).select { |x| x.include?('Pinocchio') && !x.include?('Test') }[0]
    geppettos = raw_claim['page'].search('h3').collect(&:text).select { |x| x.include?('Geppetto') }[0]
    pinocchio_map = { 'One' => 1, 'Two' => 2, 'Three' => 3, 'Four' => 4 }
    claim_result = nil
    claim_result_score = nil
    if pinocchios.nil? && !geppettos.nil?
      claim_result = 'True'
      claim_result_score = 1
    else
      score = begin
                pinocchios.split(' ').collect { |x| pinocchio_map[x] }.compact.first
              rescue StandardError
                nil
              end
      if score == 4
        claim_result = 'False'
      elsif score.nil?
        claim_result = 'Inconclusive'
        score = 2
      else
        claim_result = 'Partly False'
      end
      claim_result_score = (4 - score) / 4.0
    end
    time = begin
             Time.parse(raw_claim['page'].search('div.display-date').text)
           rescue StandardError
             nil
           end
    if time.nil?
      time = begin
               Time.parse(raw_claim['page'].search('div.date').first.attributes['content'].value)
             rescue StandardError
               nil
             end
    end
    author = begin
               raw_claim['page'].search('div.author-names span.author-name').first.text
             rescue StandardError
               nil
             end
    author_link = begin
                    raw_claim['page'].search('div.author-names a.author-name-link').first.attributes['href'].value
                  rescue StandardError
                    nil
                  end
    {
      service_id: Digest::MD5.hexdigest(raw_claim['url']),
      created_at: time,
      author: author,
      author_link: author_link,
      claim_headline: (begin
                         raw_claim['page'].search('header div').last.text
                       rescue StandardError
                         nil
                       end),
      claim_body: (begin
                     raw_claim['page'].search('div.article-body p').text
                   rescue StandardError
                     nil
                   end),
      claim_result: claim_result,
      claim_result_score: claim_result_score,
      claim_url: raw_claim['url'],
      raw_claim: { page: raw_claim['page'].to_s, url: raw_claim['url'] }
    }
  end
end
