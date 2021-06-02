# frozen_string_literal: true

# Parser for https://factual.afp.com, subclass of AFP's parser
require_relative('afp')
class AFPFactual < AFP
  include PaginatedReviewClaims
  def hostname
    'https://factual.afp.com'
  end
end
