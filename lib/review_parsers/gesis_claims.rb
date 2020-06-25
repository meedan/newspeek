# frozen_string_literal: true

class GESISClaims < ReviewParser
  def get_fact(fact_id)
    JSON.parse(RestClient.post('https://data.gesis.org/claimskg/sparql', { query: 'PREFIX schema: <http://schema.org/> PREFIX nif: <http://persistence.uni-leipzig.org/nlp2rdf/ontologies/nif-core#> select distinct (?claim as ?id) COALESCE(?date, "") as ?date COALESCE(?keywords, "") as ?keywords group_concat(distinct ?entities_name, ";!;") as ?mentions group_concat(distinct ?entities_name_article, ";!;") as ?mentionsArticle COALESCE(?language, "") as ?language group_concat(?citations, ";!;") as ?citations ?truthRating ?ratingName ?text COALESCE(?author, "") as ?author COALESCE(?source, "") as ?source COALESCE(?sourceURL, "") as ?sourceURL COALESCE(?link, "") as ?link where { ?claim a schema:ClaimReview . OPTIONAL{ ?claim schema:headline ?headline} . ?claim schema:reviewRating ?truth_rating_review . ?truth_rating_review schema:author <http://data.gesis.org/claimskg/organization/claimskg> . ?truth_rating_review schema:alternateName ?ratingName . ?truth_rating_review schema:ratingValue ?truthRating . OPTIONAL {?claim schema:url ?link} . ?item a schema:CreativeWork . ?item schema:text ?text . ?claim schema:itemReviewed ?item . OPTIONAL {?item schema:mentions ?entities . ?entities nif:isString ?entities_name} . OPTIONAL {?claim schema:mentions ?entities_article . ?entities_article nif:isString ?entities_name_article} . OPTIONAL {?item schema:author ?author_info .  ?author_info schema:name ?author } . OPTIONAL {?claim schema:inLanguage ?inLanguage . ?inLanguage schema:name ?language} . OPTIONAL {?claim schema:author ?sourceAuthor . ?sourceAuthor schema:name ?source . ?sourceAuthor schema:url ?sourceURL} . OPTIONAL {?item schema:keywords ?keywords} . OPTIONAL {?item schema:citation ?citations} . OPTIONAL {?item schema:datePublished ?date} . FILTER (?claim = <http://data.gesis.org/claimskg/claim_review/' + fact_id + '>) }' }, { "Accept": 'application/sparql-results+json' }))['results']['bindings'][0]
  end

  def get_claims
    gesis_ids = CSV.read('../datasets/gesis_claim_ids.csv').flatten.shuffle
    gesis_ids.each_slice(100) do |id_set|
      new_ids = id_set - ClaimReview.existing_ids(id_set, self.class.service)
      results =
        Parallel.map(new_ids, in_processes: 10, progress: 'Downloading GESIS Corpus') do |id|
          [
            id,
            (begin
                            get_fact(id)
             rescue StandardError
               nil
                          end)
          ]
        end
      process_claims(results.compact.map { |x| parse_raw_claim(Hashie::Mash[{ id: x[0], content: x[1] }]) })
    end
  end

  def parse_raw_claim(raw_claim)
    author =
      begin
                    raw_claim['content']['source']['value']
      rescue StandardError
        nil
                  end
    {
      service_id: raw_claim['id'],
      created_at: (begin
                     Time.parse(raw_claim['content']['date']['value'])
                   rescue StandardError
                     nil
                   end),
      author: author,
      author_link: (begin
                      raw_claim['content']['sourceURL']['value']
                    rescue StandardError
                      nil
                    end),
      claim_headline: (begin
                         raw_claim['content']['text']['value']
                       rescue StandardError
                         nil
                       end),
      claim_body: nil,
      claim_result: (begin
                       raw_claim['content']['ratingName']['value']
                     rescue StandardError
                       nil
                     end),
      claim_result_score: (begin
                             raw_claim['content']['truthRating']['value']
                           rescue StandardError
                             nil
                           end),
      claim_url: (begin
                    raw_claim['content']['link']['value']
                  rescue StandardError
                    nil
                  end),
      raw_claim: raw_claim
    }
  end
end
