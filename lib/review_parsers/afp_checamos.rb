require_relative 'afp'
class AFPChecamos < AFP
  include PaginatedReviewClaims
  def hostname
    "https://checamos.afp.com"
  end
end