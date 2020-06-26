# frozen_string_literal: true

describe RunReviewParser do
  describe 'instance' do
    it 'walks through perform task' do
      ReviewParser.stub(:run).with('foo').and_return(nil)
      RunReviewParser.stub(:perform_async).with('foo').and_return(nil)
      expect(RunReviewParser.new.perform('foo')).to(eq(nil))
    end
  end
end
