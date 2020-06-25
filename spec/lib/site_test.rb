# frozen_string_literal: true

describe Site do
  describe 'endpoints' do
    it 'returns a GET claim_reviews.json response' do
      ClaimReview.stub(:search).with(nil, nil, nil, nil, 20, 0).and_return([])
      code, headers, body = described_class.call(
        REQUEST_METHOD: 'GET',
        PATH_INFO: '/claim_reviews.json',
        "rack.input": StringIO.new
      )
      expect(code).to(eq(200))
      expect(JSON.parse(body[0])).to(eq([]))
    end

    it 'returns a GET claim_reviews.json response' do
      ClaimReview.stub(:search).with(nil, nil, nil, nil, 20, 0).and_return([{ bloop: 1 }])
      code, headers, body = described_class.call(
        REQUEST_METHOD: 'GET',
        PATH_INFO: '/claim_reviews.json',
        "rack.input": StringIO.new
      )
      expect(code).to(eq(200))
      expect(JSON.parse(body[0])).to(eq([{ bloop: 1 }]))
    end
  end
end
