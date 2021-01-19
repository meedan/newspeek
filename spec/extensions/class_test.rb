# frozen_string_literal: true

describe Class do
  describe 'instance' do
    it 'lists subclasses' do
      expect(ClaimReviewParser.enabled_subclasses.class).to(eq(Array))
    end

    it 'lists nonempty subclasses for ClaimReviewParser' do
      expect(ClaimReviewParser.enabled_subclasses.empty?).to(eq(false))
    end

    it 'lists empty subclasses for API' do
      expect(API.subclasses).to(eq([]))
    end
  end
end
