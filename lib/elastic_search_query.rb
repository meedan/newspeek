# frozen_string_literal: true

class ElasticSearchQuery
  def self.service_query(service)
    {
      "query": {
        "match": {
          "service": service
        }
      }
    }
  end

  def self.base_query(limit, offset)
    {
      "size": limit||20,
      "from": offset||0,
      "sort": [{"created_at": {"order": "desc"}}],
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
        "should": matches.map { |match| { "match_phrase": { match_type => match } } },
        "minimum_should_match": 1
      }
    }
  end

  def self.default_time_clause(key)
    {
      range: {
        key => {
          format: 'strict_date_optional_time'
        }
      }
    }
  end

  def self.formatted_time(time)
    Time.parse(time).strftime('%FT%R:%S.%LZ')
  end
  
  def self.start_end_date_range(key, start_time, end_time)
    time_clause = self.default_time_clause(key)
    time_clause[:range][key][:gte] = self.formatted_time(start_time) if start_time
    time_clause[:range][key][:lte] = self.formatted_time(end_time) if end_time
    time_clause
  end

  def self.start_end_date_range_query(key, start_time, end_time)
    if start_time || end_time
      return self.start_end_date_range(key, start_time, end_time)
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

  def self.claim_review_search_query(opts)
    query = ElasticSearchQuery.service_scoped_limit_offset_query(opts[:service], opts[:per_page], opts[:offset])
    if opts[:search_query]
      query[:query][:bool][:filter] << ElasticSearchQuery.query_match_clause('claim_review_headline', opts[:search_query])
    end
    time_clause = ElasticSearchQuery.start_end_date_range_query('created_at', opts[:start_time], opts[:end_time])
    query[:query][:bool][:filter] << time_clause unless time_clause.empty?
    query
  end
end
