# frozen_string_literal: true

describe Settings do
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

  end
end
