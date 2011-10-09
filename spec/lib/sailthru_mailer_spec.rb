require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "SailthruMailer" do
  context "Setup" do
    it "should allow for configuration" do
      SailthruMailer.settings = {
        :api_key => "XYZ",
        :api_secret => "ABC",
        :api_url => "https://api.sailthru.com"
      }
      SailthruMailer.settings[:api_key].should eql "XYZ"
    end
  end
end
