# frozen_string_literal: true

# Parser for https://checamos.afp.com, subclass of AFP's parser
require_relative('afp')
class AFPChecamos < AFP
  include PaginatedReviewClaims
  def hostname
    'https://checamos.afp.com'
  end
end
