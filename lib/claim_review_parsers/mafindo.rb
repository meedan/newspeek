# frozen_string_literal: true

# Parser for https://mafindo.github.io/docs/v2/#the-news-object
# curl --request POST \
#   --url https://yudistira.turnbackhoax.id/api/antihoax/ \
#   --header 'Content-Type: application/x-www-form-urlencoded' \
#   --header 'Accept: application/json' \
#   --data 'key=123456&id=891&limit=1&offset=1'
class Mafindo < ClaimReviewParser
  def initialize(cursor_back_to_date = nil, overwrite_existing_claims=false)
    super(cursor_back_to_date, overwrite_existing_claims)
    @fact_list_page_parser = 'json'
    @raw_response = {}
    @authors = get_authors
  end

  def get_authors
    JSON.parse(RestClient.post(self.hostname+self.authors_endpoint, {key: Settings.get("mafindo_api_key")}))
  end

  def service_key
    'mafindo_api_key'
  end

  def hostname
    'https://yudistira.turnbackhoax.id/api'
  end

  def fact_list_path
    '/antihoax'
  end

  def authors_endpoint
    '/antihoax/get_authors'
  end

  def request_fact_page(page, limit)
    RestClient.post(self.hostname+self.fact_list_path, {key: Settings.get("mafindo_api_key"), limit: limit, offset: page*limit})
  end

  def get_fact_page_response(page)
    JSON.parse(
      request_fact_page(page, 200)
    )
  end

  def url_from_id(id)
    "https://gfd.turnbackhoax.id/focus/#{id}"
  end

  def get_claim_reviews
    return false if service_key_is_needed?
    page = 1
    raw_claims = store_new_claim_reviews_for_page(page)
    until finished_iterating?(raw_claims)
      page += 1
      raw_claims = store_new_claim_reviews_for_page(page)
    end
  end

  def store_new_claim_reviews_for_page(page = 1)
    response = get_fact_page_response(page)
    existing_urls = get_existing_urls(response.collect{|d| url_from_id(d["id"])})
    process_claim_reviews(
      parse_raw_claim_reviews(
        response.reject{|d| existing_urls.include?(url_from_id(d["id"]))}
      )
    )
  end
  
  def rating_map
    {
      "Misleading Content" => 0.5,
      "False Connection" => 0.0,
      "Satire" => 0.5,
      "Fabricated Content" => 0.5,
      "Impostor Content" => 0.5,
      "Manipulated Content" => 0.5,
      "False Context" => 0.0,
      "TRUE" => 1,
      "Clarification" => 0.5,
      "-" => 0.5,
    }
  end

  def author_link_from_authors(authors)
    authors[0] && authors[0]["website"]
  end

  def authors_from_authors(authors)
    authors.collect{|x| x['nama']}.join(", ")
  end

  def parse_raw_claim_review(raw_claim_review)
    authors = @authors.select{|x| !([x["id"]]&[raw_claim_review['authors']].flatten).empty?}
    {
      id: raw_claim_review['id'],
      created_at: Time.parse(raw_claim_review['tanggal']),
      author: authors_from_authors(authors),
      author_link: author_link_from_authors(authors),
      claim_review_headline: raw_claim_review['title'],
      claim_review_body: raw_claim_review['fact'],
      claim_review_reviewed: raw_claim_review['source_link'],
      claim_review_image_url: raw_claim_review['picture1'],
      claim_review_result: raw_claim_review['classification'],
      claim_review_result_score: rating_map[raw_claim_review['classification']],
      claim_review_url: url_from_id(raw_claim_review['id']),
      raw_claim_review: raw_claim_review
    }
  end
end
# Mafindo.new.get_claim_reviews