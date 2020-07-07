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

  def get_pinocchios(page)
    page.search('h3').map(&:text).select { |x| x.include?('Pinocchio') && !x.include?('Test') }[0]
  end

  def get_geppettos(page)
    page.search('h3').map(&:text).select { |x| x.include?('Geppetto') }[0]
  end
  
  def pinocchio_map
    {
      'One' => 1,
      'Two' => 2,
      'Three' => 3,
      'Four' => 4
    }
  end

  def parse_partial_truthfulness(pinocchios, geppettos)
    claim_result = nil
    claim_result_score = nil
    score = nil
    begin
      if pinocchios
        score = pinocchios.split(' ').map { |x| pinocchio_map[x] }.compact.first
      end
    rescue StandardError => e
      Error.log(e)
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
    [claim_result, claim_result_score]
  end

  def parse_truthfulness(pinocchios, geppettos)
    claim_result = nil
    claim_result_score = nil
    if pinocchios.nil? && !geppettos.nil?
      claim_result = 'True'
      claim_result_score = 1
    else
      claim_result, claim_result_score = parse_partial_truthfulness(pinocchios, geppettos)
    end
    [claim_result, claim_result_score]
  end

  def claim_result_and_claim_result_score_from_page(page)
    pinocchios = get_pinocchios(page)
    geppettos = get_geppettos(page)
    claim_result, claim_result_score = parse_truthfulness(pinocchios, geppettos)
    [claim_result, claim_result_score]
  end

  def author_from_page(page)
    page.search('div.author-names span.author-name').first.text
  rescue StandardError => e
    Error.log(e)
  end

  def author_link_from_page(page)
    link = page.search('div.author-names a.author-name-link').first
    link.attributes['href'].value if link
  end

  def claim_headline_from_page(page)
    page.search('header div').last.text
  rescue StandardError => e
    Error.log(e)
  end

  def claim_body_from_page(page)
    page.search('div.article-body p').text
  end

  def author_from_news_article(news_article)
    if news_article["author"].class == Hash
      news_article["author"]["name"]
    elsif news_article["author"].class == Array
      news_article["author"].collect{|x| x["name"]}.join(", ")
    end
  end

  def claim_review_image_url_from_news_article(news_article)
    if news_article["image"].class == Hash
      news_article["image"]["url"]
    else
      news_article["image"].first && news_article["image"].first["url"]
    end
  end

  def parse_raw_claim_review(raw_claim_review)
    claim_result, claim_result_score = claim_result_and_claim_result_score_from_page(raw_claim_review['page'])
    news_article = JSON.parse(raw_claim_review["page"].search("script").select{|x| x.attributes["type"] && x.attributes["type"].value == "application/ld+json"}.first.text)
    {
      id: Digest::MD5.hexdigest(raw_claim_review['url']||""),
      created_at: Time.parse(news_article["datePublished"]),
      author: author_from_news_article(news_article),
      author_link: author_link_from_page(raw_claim_review['page']),
      claim_review_headline: news_article["headline"],
      claim_review_body: claim_body_from_page(raw_claim_review['page']),
      claim_review_image_url: claim_review_image_url_from_news_article(news_article),
      claim_review_result: claim_result,
      claim_review_result_score: claim_result_score,
      claim_review_url: raw_claim_review['url'],
      raw_claim_review: { page: news_article, url: raw_claim_review['url'] }
    }
  end
end
