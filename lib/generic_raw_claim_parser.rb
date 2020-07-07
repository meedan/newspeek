module GenericRawClaimParser
  def parse_raw_claim_review(raw_claim_review)
    {
      id: id_from_raw_claim_review(raw_claim_review),
      created_at: created_at_from_raw_claim_review(raw_claim_review),
      author: author_from_raw_claim_review(raw_claim_review),
      author_link: author_link_from_raw_claim_review(raw_claim_review),
      claim_review_headline: claim_headline_from_raw_claim_review(raw_claim_review),
      claim_review_body: nil,
      claim_review_result: claim_result_from_raw_claim_review(raw_claim_review),
      claim_review_result_score: claim_result_score_from_raw_claim_review(raw_claim_review),
      claim_review_url: claim_url_from_raw_claim_review(raw_claim_review),
      raw_claim_review: raw_claim_review
    }
  end
end