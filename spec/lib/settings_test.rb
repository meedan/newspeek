# frozen_string_literal: true

describe Settings do
  before do
    stub_request(:any, Settings.get('es_host')).to_raise(SocketError)
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
    
    it 'raises Elastic Search Error when not able to connect' do
      stub_request(:any, Settings.get('es_host')).to_raise(SocketError)
      expect { Settings.check_into_elasticsearch(1, false) }.to raise_error(StandardError)
    end

    it 'expects default parallel task count of 1' do
      expect(Settings.default_task_count("bogus")).to(eq(1))
    end

    it 'expects specified parallel task count for get_claim_reviews of 10' do
      expect(Settings.default_task_count(:get_claim_reviews)).to(eq(10))
    end
    
    it 'returns 2 hours on QA interevent time' do
      Settings.stub(:in_qa_mode?).and_return(true)
      expect(Settings.task_interevent_time).to(eq(60*60*2))
    end

    it 'returns 1 hour on QA interevent time' do
      Settings.stub(:in_qa_mode?).and_return(false)
      expect(Settings.task_interevent_time).to(eq(60*60))
    end
  end
end
