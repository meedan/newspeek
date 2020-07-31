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
      expect(Settings.get('es_index_name')).to(eq('claim_reviews'))
    end

    it 'has defaults' do
      expect(Settings.defaults.class).to(eq(Hash))
    end
    
    it 'fires timeout on failed es connect' do
      expect{Settings.check_into_elasticsearch(1, false)}.to(raise_error(StandardError))
    end
  end
end
