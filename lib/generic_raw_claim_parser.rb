module GenericRawClaimParser
  def parse_raw_claim(raw_claim)
    {
      id: id_from_raw_claim(raw_claim),
      created_at: created_at_from_raw_claim(raw_claim),
      author: author_from_raw_claim(raw_claim),
      author_link: author_link_from_raw_claim(raw_claim),
      claim_headline: claim_headline_from_raw_claim(raw_claim),
      claim_body: nil,
      claim_result: claim_result_from_raw_claim(raw_claim),
      claim_result_score: claim_result_score_from_raw_claim(raw_claim),
      claim_url: claim_url_from_raw_claim(raw_claim),
      raw_claim: raw_claim
    }
  end
end