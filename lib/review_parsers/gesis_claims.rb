# frozen_string_literal: true

# Parser for
class GESISClaims < ReviewParser
  include GenericRawClaimParser
  def get_fact_ids(page, limit = 100)
    JSON.parse(
      RestClient.post(
        'https://data.gesis.org/claimskg/sparql', {
          query: "PREFIX schema: <http://schema.org/> PREFIX nif: <http://persistence.uni-leipzig.org/nlp2rdf/ontologies/nif-core#> select * where {select distinct (?claims as ?id) COALESCE(?date, 'Unknown') as ?date ?truthRating ?ratingName COALESCE(?author, 'Unknown') as ?author COALESCE(?link, '') as ?link?text where { ?claims a schema:ClaimReview . OPTIONAL {?claims schema:headline ?headline} . ?claims schema:reviewRating ?truth_rating_review . ?truth_rating_review schema:alternateName ?ratingName . ?truth_rating_review schema:author <http://data.gesis.org/claimskg/organization/claimskg> . ?truth_rating_review schema:ratingValue ?truthRating . OPTIONAL {?claims schema:url ?link} . ?item a schema:CreativeWork . ?claims schema:itemReviewed ?item . ?item schema:text ?text . OPTIONAL {?item schema:author ?author_info . ?author_info schema:name ?author } . OPTIONAL {?item schema:datePublished ?date} . }ORDER BY desc (?date)}LIMIT #{limit} OFFSET #{limit * (page - 1)}"
        }, {
          "Accept": 'application/sparql-results+json'
        }
      )
    )['results']['bindings'].collect { |c| [c['id']['value'].split('/').last, id_from_raw_claim_review({ 'content' => c })] }
  rescue StandardError => e
    Error.log(e)
    []
  end

  def get_all_fact_ids
    page = 1
    results = get_fact_ids(page)
    all_results = results
    until results.empty?
      page += 1
      results = get_fact_ids(page)
      results.each do |id|
        all_results << id
      end
    end
    all_results
  end

  def get_fact(fact_id)
    JSON.parse(
      RestClient.post(
        'https://data.gesis.org/claimskg/sparql', {
          query: 'PREFIX schema: <http://schema.org/> PREFIX nif: <http://persistence.uni-leipzig.org/nlp2rdf/ontologies/nif-core#> select distinct (?claim as ?id) COALESCE(?date, "") as ?date COALESCE(?keywords, "") as ?keywords group_concat(distinct ?entities_name, ";!;") as ?mentions group_concat(distinct ?entities_name_article, ";!;") as ?mentionsArticle COALESCE(?language, "") as ?language group_concat(?citations, ";!;") as ?citations ?truthRating ?ratingName ?text COALESCE(?author, "") as ?author COALESCE(?source, "") as ?source COALESCE(?sourceURL, "") as ?sourceURL COALESCE(?link, "") as ?link where { ?claim a schema:ClaimReview . OPTIONAL{ ?claim schema:headline ?headline} . ?claim schema:reviewRating ?truth_rating_review . ?truth_rating_review schema:author <http://data.gesis.org/claimskg/organization/claimskg> . ?truth_rating_review schema:alternateName ?ratingName . ?truth_rating_review schema:ratingValue ?truthRating . OPTIONAL {?claim schema:url ?link} . ?item a schema:CreativeWork . ?item schema:text ?text . ?claim schema:itemReviewed ?item . OPTIONAL {?item schema:mentions ?entities . ?entities nif:isString ?entities_name} . OPTIONAL {?claim schema:mentions ?entities_article . ?entities_article nif:isString ?entities_name_article} . OPTIONAL {?item schema:author ?author_info .  ?author_info schema:name ?author } . OPTIONAL {?claim schema:inLanguage ?inLanguage . ?inLanguage schema:name ?language} . OPTIONAL {?claim schema:author ?sourceAuthor . ?sourceAuthor schema:name ?source . ?sourceAuthor schema:url ?sourceURL} . OPTIONAL {?item schema:keywords ?keywords} . OPTIONAL {?item schema:citation ?citations} . OPTIONAL {?item schema:datePublished ?date} . FILTER (?claim = <http://data.gesis.org/claimskg/claim_review/' + fact_id + '>) }'
        }, {
          "Accept": 'application/sparql-results+json'
        }
      )
    )['results']['bindings'][0]
  rescue StandardError => e
    Error.log(e)
    {}
  end

  def get_claim_reviews
    get_all_fact_ids.shuffle.each_slice(100) do |id_set|
      existing_ids = ClaimReview.existing_ids(id_set.collect(&:last), self.class.service)
      new_ids = id_set.reject { |x| existing_ids.include?(x.last) }.collect(&:first)
      results =
        Parallel.map(new_ids, in_processes: 10, progress: 'Downloading GESIS Corpus') do |id|
          [id, get_fact(id)]
        end
      process_claim_reviews(results.compact.map { |x| parse_raw_claim_review(Hashie::Mash[{ id: x[0], content: x[1] }]) })
    end
  end

  def author_from_raw_claim_review(raw_claim_review)
    raw_claim_review['content']['source']['value']
  rescue StandardError => e
    Error.log(e)
  end

  def created_at_from_raw_claim_review(raw_claim_review)
    raw_claim_review['content'] &&
    raw_claim_review['content']['date'] && 
    raw_claim_review['content']['date']['value'] &&
    !raw_claim_review['content']['date']['value'].empty? &&
    Time.parse(raw_claim_review['content']['date']['value']) ||
    nil
  rescue StandardError => e
    Error.log(e)
  end

  def author_link_from_raw_claim_review(raw_claim_review)
    raw_claim_review['content']['sourceURL']['value']
  rescue StandardError => e
    Error.log(e)
  end

  def claim_headline_from_raw_claim_review(raw_claim_review)
    raw_claim_review['content']['text']['value']
  rescue StandardError => e
    Error.log(e)
  end

  def claim_result_from_raw_claim_review(raw_claim_review)
    raw_claim_review['content']['ratingName']['value']
  rescue StandardError => e
    Error.log(e)
  end

  def claim_result_score_from_raw_claim_review(raw_claim_review)
    raw_claim_review['content']['truthRating']['value']
  rescue StandardError => e
    Error.log(e)
  end

  def claim_url_from_raw_claim_review(raw_claim_review)
    raw_claim_review['content']['link']['value']
  rescue StandardError => e
    Error.log(e)
  end

  def id_from_raw_claim_review(raw_claim_review)
    Digest::MD5.hexdigest(raw_claim_review['content']['id']['value'].split('/').last)
  rescue StandardError => e
    Error.log(e)
    Digest::MD5.hexdigest('')
  end
end
