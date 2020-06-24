describe String do
  describe "instance" do
    it "should underscore" do
      expect("BlahBloop".underscore).to eq("blah_bloop")
      expect("GESIS".underscore).to eq("gesis")
    end
  end
end
class String
  def underscore
    word = self.to_s.dup
    word.gsub!('::', '/')
    word.gsub!(/([A-Z\d]+)([A-Z][a-z])/,'\1_\2')
    word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
    word.tr!("-", "_")
    word.downcase!
    word
  end
end