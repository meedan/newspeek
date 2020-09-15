# frozen_string_literal: true

describe Settings do
  before do
    stub_request(:any, 'http://elasticsearch:9200/').to_raise(SocketError)
  end
  describe 'class methods' do
    it 'has allows get access' do
      expect(Settings.get('blah')).to(eq(nil))
    end

    it 'has allows get for default value' do
      expect(['claim_reviews', 'claim_reviews_test'].include?(Settings.get_es_index_name)).to(eq(true))
    end

    it 'has defaults' do
      expect(Settings.defaults.class).to(eq(Hash))
    end
    
    it 'fires timeout on failed es connect - this may pass if ES is running on the machine!' do
      WebMock.allow_net_connect!
      result = Settings.check_into_elasticsearch(1, false) rescue false
      expect([nil, false].include?(result)).to(eq(true))
      WebMock.disable_net_connect!
    end
  end
end
