module PaginatedReviewClaims

  def get_url(url)
    begin
      response = RestClient.get(
        url
      )
    rescue RestClient::NotFound, SocketError, Errno::ETIMEDOUT
      return nil
    end
  end

  def parsed_fact_list_page(page=1)
    response = get_url(hostname+fact_list_path(page))
    return nil if response.nil?
    if @fact_list_page_parser == "html"
      Nokogiri.parse(response)
    elsif @fact_list_page_parser == "json"
      JSON.parse(response)
    end
  end

  def get_fact_page_urls(page=1)
    response = parsed_fact_list_page(page)
    if response
      if @fact_list_page_parser == "html"
        response.search(url_extraction_search).collect{|atag| url_extractor(atag)}
      elsif @fact_list_page_parser == "json"
        url_extractor(response)
      end
    else
      return []
    end
  end

  def parsed_fact_page(fact_page_url)
    parsed_page = Nokogiri.parse(get_url(fact_page_url)) rescue nil
    return nil if parsed_page.nil?
    [fact_page_url, parse_raw_claim(Hashie::Mash[{page: parsed_page, url: fact_page_url}])]
  end

  def get_new_fact_page_urls(page)
    page_urls = get_fact_page_urls(page)
    existing_urls = ClaimReview.existing_urls(page_urls, self.class.service)
    page_urls-existing_urls
  end

  def store_claims_for_page(page)
    process_claims(
      get_parsed_fact_pages_from_urls(
        get_new_fact_page_urls(
          page
        )
      )
    )
  end

  def get_claims
    page = 1
    processed_claims = store_claims_for_page(page)
    while !finished_iterating?(processed_claims)
      page += 1
      processed_claims = store_claims_for_page(page)
    end
  end

  def get_parsed_fact_pages_from_urls(urls)
    if @run_in_parallel
      Hash[Parallel.map(urls, in_processes: 5, progress: "Downloading #{self.class} Corpus") { |fact_page_url| 
        parsed_fact_page(fact_page_url) rescue nil
      }.compact].values
    else
      Hash[urls.collect { |fact_page_url| 
        parsed_fact_page(fact_page_url)
      }.compact].values
    end
  end
end