# frozen_string_literal: true

require_relative('india_today')
class AajtakIndiaToday < IndiaToday
  include PaginatedReviewClaims
  def hostname
    'https://aajtak.intoday.in'
  end

  def fact_list_path(page = 1)
    # they start with 0-indexes, so push back internally
    "/fact-check.html/#{page*30}"
  end

  def url_extraction_search
    'div.content-article'
  end

  def headline_search
    'h1.secArticleTitle'
  end

  def body_search
    'div.storyBody p'
  end

  def url_extractor(article)
    hostname + article.search("a").first.attributes['href'].value
  end
end
