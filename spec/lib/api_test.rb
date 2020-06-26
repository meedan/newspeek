# frozen_string_literal: true

describe API do
  describe 'class' do
    it 'has a claim review endpoint' do
      ClaimReview.stub(:search).with(nil, nil, nil, nil, 20, 0).and_return([])
      expect(described_class.claim_reviews({})).to(eq([]))
    end

    it 'has a nonempty claim review endpoint' do
      ClaimReview.stub(:search).with(nil, nil, nil, nil, 20, 0).and_return([{ bloop: 1 }])
      expect(described_class.claim_reviews({})).to(eq([{ bloop: 1 }]))
    end

    it 'has an about page' do
      expect(described_class.about.class).to(eq(Hash))
    end
  end
end
