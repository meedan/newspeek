# frozen_string_literal: true

describe Class do
  describe 'instance' do
    it 'should list subclasses' do
      expect(ReviewParser.subclasses.class).to eq(Array)
    end

    it 'should list nonempty subclasses for ReviewParser' do
      expect(ReviewParser.subclasses.empty?).to eq(false)
    end

    it 'should list empty subclasses for API' do
      expect(API.subclasses).to eq([])
    end
  end
end
