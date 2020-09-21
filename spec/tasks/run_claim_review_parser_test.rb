# frozen_string_literal: true

describe RunClaimReviewParser do
  describe 'instance' do
    it 'walks through perform task' do
      ClaimReviewParser.stub(:run).with('foo', nil, false).and_return(nil)
      RunClaimReviewParser.stub(:perform_in).with(60 * 60, 'foo').and_return(nil)
      expect(RunClaimReviewParser.new.perform('foo')).to(eq(nil))
    end
  end
end
