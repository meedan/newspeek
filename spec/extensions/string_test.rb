# frozen_string_literal: true

describe String do
  describe 'instance' do
    it 'underscores' do
      expect('BlahBloop'.underscore).to(eq('blah_bloop'))
      expect('GESIS'.underscore).to(eq('gesis'))
    end
  end
end
