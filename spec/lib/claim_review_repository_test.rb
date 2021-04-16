# frozen_string_literal: true

describe ClaimReviewRepository do
  describe 'class' do
    it 'expects setting number of shards' do
      expect(described_class.settings.settings).to(eq({ number_of_shards: 1 }))
    end

    it 'expects index_name' do
      expect(described_class.index_name).to(eq(Settings.get_es_index_name))
    end

    it 'expects klass' do
      expect(described_class.klass).to(eq(ClaimReview))
    end

    it 'expects perfunctory walkthrough of index creator' do
      described_class.any_instance.stub(:create_index!).and_return(nil)
      expect(described_class.init_index).to(eq(nil))
    end

    it 'expects perfunctory walkthrough of failed safe_init_index' do
      described_class.any_instance.stub(:create_index!).and_return(nil)
      Elasticsearch::API::Indices::IndicesClient.any_instance.stub(:exists).and_return(true)
      expect(described_class.safe_init_index).to(eq(false))
    end

    it 'expects perfunctory walkthrough of successful safe_init_index' do
      described_class.any_instance.stub(:create_index!).and_return(nil)
      Elasticsearch::API::Indices::IndicesClient.any_instance.stub(:exists).and_return(false)
      expect(described_class.safe_init_index).to(eq(true))
    end
  end
end
