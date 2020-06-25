# frozen_string_literal: true

class ElasticSearchQuery
  def self.base_query(limit, offset)
    {
      "size": limit,
      "from": offset,
      "query": {
        "bool": {
          "must": [
            {
              "match_all": {}
            }
          ],
          "filter": [],
          "should": [],
          "must_not": []
        }
      }
    }
  end

  def self.query_match_clause(key, value)
    {
      "match_phrase": {
        key => value
      }
    }
  end

  def self.multi_match_query(match_type, matches)
    {
      "bool": {
        "should": matches.collect { |match| { "match_phrase": { match_type => match } } },
        "minimum_should_match": 1
      }
    }
  end

  def self.start_end_date_range(key, start_time, end_time)
    if start_time || end_time
      time_clause = {
        range: {
          key => {
            format: 'strict_date_optional_time'
          }
        }
      }
      time_clause[:range][key][:gte] = Time.parse(start_time).strftime('%FT%R:%S.%LZ') if start_time
      time_clause[:range][key][:lte] = Time.parse(end_time).strftime('%FT%R:%S.%LZ') if end_time
      time_clause
    else
      {}
    end
  end

  def self.service_scoped_limit_offset_query(service, limit, offset)
    query = ElasticSearchQuery.base_query(limit, offset)
    query[:query][:bool][:filter] << ElasticSearchQuery.query_match_clause('service', service) if service
    query
  end

  def self.multi_match_against_service(matches, match_type, service)
    query = ElasticSearchQuery.service_scoped_limit_offset_query(service, matches.length, 0)
    query[:query][:bool][:filter] << ElasticSearchQuery.multi_match_query(match_type, matches)
    query
  end

  def self.claim_review_search_query(search_query = nil, service = nil, start_time = nil, end_time = nil, limit = 20, offset = 0)
    query = ElasticSearchQuery.service_scoped_limit_offset_query(service, limit, offset)
    if search_query
      query[:query][:bool][:filter] << ElasticSearchQuery.query_match_clause('claim_headline', search_query)
    end
    time_clause = ElasticSearchQuery.start_end_date_range('created_at', start_time, end_time)
    query[:query][:bool][:filter] << time_clause unless time_clause.empty?
    query
  end
end
