# frozen_string_literal: true

describe Language do
  describe 'class methods' do
    it 'returns non-reliable language' do
      expect(Language.get_language('blah wow')).to(eq('en'))
    end

    it 'returns nil on non-reliable language' do
      expect(Language.get_reliable_language('blah wow')).to(eq(nil))
    end

    it 'returns nil on non-reliable language' do
      expect(Language.get_reliable_language('Well this is obviously an English sentence')).to(eq('en'))
    end
  end
end
