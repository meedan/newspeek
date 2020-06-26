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
    Nokogiri.parse('<html>' + json_response['rendering'] + '</html>').search('div.story-headline h2 a').map { |x| hostname + x.attributes['href'].value }
  end

  def claim_result_and_claim_result_score_from_page(page)
    pinocchios = page.search('h3').map(&:text).select { |x| x.include?('Pinocchio') && !x.include?('Test') }[0]
    geppettos = page.search('h3').map(&:text).select { |x| x.include?('Geppetto') }[0]
    pinocchio_map = { 'One' => 1, 'Two' => 2, 'Three' => 3, 'Four' => 4 }
    claim_result = nil
    claim_result_score = nil
    if pinocchios.nil? && !geppettos.nil?
      claim_result = 'True'
      claim_result_score = 1
    else
      score = nil
      begin
        score = pinocchios.split(' ').map { |x| pinocchio_map[x] }.compact.first
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
    return [claim_result, claim_result_score]
  end
  
  def time_from_page(page)
    time = nil
    begin
      time = Time.parse(page.search('div.display-date').text)
    rescue StandardError
      nil
    end
    if time.nil?
      begin
        time = Time.parse(page.search('div.date').first.attributes['content'].value)
      rescue StandardError
        nil
      end
    end
    time
  end

  def author_from_page(page)
    begin
      page.search('div.author-names span.author-name').first.text
    rescue StandardError
      nil
    end
  end
  
  def author_link_from_page(page)
    begin
      page.search('div.author-names a.author-name-link').first.attributes['href'].value
    rescue StandardError
      nil
    end
  end

  def claim_headline_from_page(page)
    begin
     page.search('header div').last.text
    rescue StandardError
     nil
    end
  end

  def claim_body_from_page(page)
    page.search('div.article-body p').text
  end

  def parse_raw_claim(raw_claim)
    claim_result, claim_result_score = claim_result_and_claim_result_score_from_page(raw_claim['page'])
    {
      service_id: Digest::MD5.hexdigest(raw_claim['url']),
      created_at: time_from_page(raw_claim['page']),
      author: author_from_page(raw_claim['page']),
      author_link: author_link_from_page(raw_claim['page']),
      claim_headline: claim_headline_from_page(raw_claim['page']),
      claim_body: claim_body_from_page(raw_claim['page']),
      claim_result: claim_result,
      claim_result_score: claim_result_score,
      claim_url: raw_claim['url'],
      raw_claim: { page: raw_claim['page'].to_s, url: raw_claim['url'] }
    }
  end
end
