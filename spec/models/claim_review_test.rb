# frozen_string_literal: true

describe ClaimReview do
  describe 'instance' do
    it 'responds to to_hash' do
      expect(ClaimReview.new({}).to_hash).to(eq({}))
    end
  end
  describe 'class' do
    it 'has mandatory fields' do
      expect(described_class.mandatory_fields).to(eq(%w[claim_headline claim_url created_at id]))
    end

    it 'fails validation on nil fields' do
      expect(described_class.validate_claim({})).to(eq(nil))
    end

    it 'validates MVP claim' do
      validated = described_class.validate_claim(Hashie::Mash[{ raw_claim: {}, claim_headline: 'wow', claim_url: 'http://example.com', created_at: Time.parse('2020-01-01'), id: 123 }])
      expect(validated).to(eq({ 'claim_headline' => 'wow', 'claim_url' => 'http://example.com', 'created_at' => '2020-01-01T00:00:00Z', 'id' => 123 }))
    end

    it 'saves MVP claim' do
      claim = Hashie::Mash[{ claim_headline: 'wow', claim_url: 'http://example.com', created_at: Time.parse('2020-01-01').strftime('%Y-%m-%dT%H:%M:%SZ'), id: 123 }]
      ClaimReviewRepository.any_instance.stub(:save).with(anything).and_return({ _index: 'claim_reviews', _type: 'claim_review', _id: 'vhV84XIBOGf2XeyOAD12', _version: 1, result: 'created', _shards: { total: 2, successful: 1, failed: 0 }, _seq_no: 130_821, _primary_term: 2 })
      expect(described_class.save_claim(claim, 'google')).to(eq({ _index: 'claim_reviews', _type: 'claim_review', _id: 'vhV84XIBOGf2XeyOAD12', _version: 1, result: 'created', _shards: { total: 2, successful: 1, failed: 0 }, _seq_no: 130_821, _primary_term: 2 }))
    end

    it 'expects repository instance' do
      expect(described_class.repository.class).to(eq(ClaimReviewRepository))
    end

    it 'expects client instance' do
      expect(described_class.client.class).to(eq(Elasticsearch::Transport::Client))
    end

    it 'expects non-empty get hits' do
      Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything).and_return({ 'hits' => { 'hits' => [{ '_source' => { 'claim_url' => 1 } }] } })
      expect(described_class.get_hits({})).to(eq([{ 'claim_url' => 1 }]))
    end

    it 'expects empty get hits' do
      Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything).and_return({ 'hits' => { 'hits' => [] } })
      expect(described_class.get_hits({})).to(eq([]))
    end

    it 'expects non-empty extract_matches' do
      Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything).and_return({ 'hits' => { 'hits' => [{ '_source' => { 'service' => 'google', 'claim_url' => 1 } }] } })
      expect(described_class.extract_matches([1], 'claim_url', 'google')).to(eq([1]))
    end

    it 'expects empty get extract_matches' do
      Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything).and_return({ 'hits' => { 'hits' => [] } })
      expect(described_class.extract_matches([1], 'claim_url', 'google')).to(eq([]))
    end

    it 'expects non-empty existing_ids' do
      Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything).and_return({ 'hits' => { 'hits' => [{ '_source' => { 'service' => 'google', 'id' => 1 } }] } })
      expect(described_class.existing_ids([1], 'google')).to(eq([1]))
    end

    it 'expects empty get existing_ids' do
      Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything).and_return({ 'hits' => { 'hits' => [] } })
      expect(described_class.existing_ids([1], 'google')).to(eq([]))
    end

    it 'expects non-empty existing_urls' do
      Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything).and_return({ 'hits' => { 'hits' => [{ '_source' => { 'service' => 'google', 'claim_url' => 1 } }] } })
      expect(described_class.existing_urls([1], 'google')).to(eq([1]))
    end

    it 'expects empty get existing_urls' do
      Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything).and_return({ 'hits' => { 'hits' => [] } })
      expect(described_class.existing_urls([1], 'google')).to(eq([]))
    end
  end

  it 'fails to store MVP claim' do
    claim = Hashie::Mash[{ raw_claim: {}, claim_headline: 'wow', claim_url: 'http://example.com', created_at: Time.parse('2020-01-01'), id: 123 }]
    Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything).and_return({ 'hits' => { 'hits' => [{ '_source' => { 'service' => 'google', 'id' => 123 } }] } })
    ClaimReviewRepository.any_instance.stub(:save).with(claim.merge(service: 'google')).and_return({ _index: 'claim_reviews', _type: 'claim_review', _id: 'vhV84XIBOGf2XeyOAD12', _version: 1, result: 'created', _shards: { total: 2, successful: 1, failed: 0 }, _seq_no: 130_821, _primary_term: 2 })
    expect(described_class.store_claim(claim, 'google')).to(eq(nil))
  end

  it 'stores MVP claim' do
    claim = Hashie::Mash[{ raw_claim: {}, claim_headline: 'wow', claim_url: 'http://example.com', created_at: Time.parse('2020-01-01'), id: 123 }]
    Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything).and_return({ 'hits' => { 'hits' => [] } })
    ClaimReviewRepository.any_instance.stub(:save).with(anything).and_return({ _index: 'claim_reviews', _type: 'claim_review', _id: 'vhV84XIBOGf2XeyOAD12', _version: 1, result: 'created', _shards: { total: 2, successful: 1, failed: 0 }, _seq_no: 130_821, _primary_term: 2 })
    expect(described_class.store_claim(claim, 'google')).to(eq({ _index: 'claim_reviews', _type: 'claim_review', _id: 'vhV84XIBOGf2XeyOAD12', _version: 1, result: 'created', _shards: { total: 2, successful: 1, failed: 0 }, _seq_no: 130_821, _primary_term: 2 }))
  end

  it 'runs a search' do
    Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything).and_return({ 'hits' => { 'hits' => [{ '_source' => { 'created_at' => Time.now.to_s, 'claim_url' => 1 } }] } })
    expect(described_class.search('', 'nil', Time.now.to_s, Time.now.to_s, 20, 0)).to(eq([{ :@context => 'http://schema.org', :@type => 'ClaimReview', :datePublished => Time.now.strftime('%Y-%m-%d'), :url => 1, :author => { name: nil, url: nil }, :claimReviewed => nil, :text => nil, :reviewRating => { :@type => 'Rating', :ratingValue => nil, :bestRating => 1, :alternateName => nil } }]))
  end

  it 'runs an empty search' do
    Elasticsearch::Transport::Client.any_instance.stub(:search).with(anything).and_return({ 'hits' => { 'hits' => [] } })
    expect(described_class.search('', 'nil', Time.now.to_s, Time.now.to_s, 20, 0)).to(eq([]))
  end

  it 'converts a claim review' do
    expect(described_class.convert_to_claim_review(Hashie::Mash[{ raw_claim: {}, claim_headline: 'wow', claim_url: 'http://example.com', created_at: Time.now.to_s, id: 123 }])).to(eq(
                                                                                                                                                                                      { :@context => 'http://schema.org', :@type => 'ClaimReview', :datePublished => Time.now.strftime('%Y-%m-%d'), :url => 'http://example.com', :author => { name: nil, url: nil }, :claimReviewed => 'wow', :text => nil, :reviewRating => { :@type => 'Rating', :ratingValue => nil, :bestRating => 1, :alternateName => nil } }
                                                                                                                                                                                    ))
  end
end
