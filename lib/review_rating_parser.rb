module ReviewRatingParser
  def get_rating(item, rating_key)
    review_rating = item['reviewRating'] || {}
    Float(String(review_rating[rating_key])) if review_rating[rating_key]
  rescue ArgumentError
    nil
  end

  def claim_result_score_from_raw_claim_review(item)
    best = get_rating(item, 'bestRating')
    worst = get_rating(item, 'worstRating')
    value = get_rating(item, 'ratingValue')
    if !best.nil? && !worst.nil? && !value.nil? && best - worst > 0
      return (value - worst) / (best - worst)
    end
    return value
  end
end