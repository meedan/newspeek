# frozen_string_literal: true

describe RunClaimReviewParser do
  describe 'instance' do
    it 'walks through perform task' do
      ClaimReviewParser.stub(:run).with('foo', nil, false).and_return(nil)
      RunClaimReviewParser.stub(:perform_in).with(60 * 60, 'foo').and_return(nil)
      expect(RunClaimReviewParser.new.perform('foo')).to(eq(nil))
    end
  end
  
  describe 'class' do
    ClaimReviewParser.enabled_subclasses.map(&:service).each do |service|
      it 'requeues when no task is present' do
        $REDIS_CLIENT.del(ClaimReview.service_heartbeat_key(service))
        expect(described_class.requeue(service)).to(eq(true))
      end

      it 'does not requeue when task is present' do
        $REDIS_CLIENT.setex(ClaimReview.service_heartbeat_key(service), 60, "test")
        expect(described_class.requeue(service)).to(eq(false))
      end
    end
  end
end
