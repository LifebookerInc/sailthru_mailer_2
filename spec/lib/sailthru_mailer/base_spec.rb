require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe SailthruMailer::Base do
  context "Sending Mail With Stubs" do
    before(:all) do
      TestMailer = Class.new(SailthruMailer::Base) 
      TestMailer.class_eval do
        def my_mail(opts = {})
          body[:x] = "y"
          body.merge!(opts)
        end
        def complex_mail(addr)
          to(addr)
          from("super-secret-address@test.net")
        end
      end
    end
    it "should proxy deliver methods to templates named after the method" do
      m = TestMailer.my_mail(:abc => "123")
      m.template.to_s.should eql "my_mail"
    end
    it "should include any data set for the body of the email in the feed" do
      m = TestMailer.my_mail(:abc => "123")
      m.formatted_vars.should eql({:x => "y", :abc => "123"})
    end
    it "should call to_hash on objects in the body if necessary" do
      MyObject = Class.new do
        def to_hash
          {
            :k => "v",
            :arr => ["one", "two", "three"]
          }
        end
      end
      m = TestMailer.my_mail(:user => MyObject.new)
      m.formatted_vars.should eql({:x => "y", :user => {:k => "v", :arr => ["one", "two", "three"]}})
    end
    it "should include default to/from addresses" do
      TestMailer.class_eval do
        defaults do
          subject("Test")
          from("test@tester.com")
        end
      end
      TestMailer.my_mail.from.should eql("test@tester.com")
      TestMailer.complex_mail("dan@lifebooker.com").from.should eql("super-secret-address@test.net")
      
      TestMailer.class_eval do
        defaults(:from => "test2@tester.com")
      end
      TestMailer.my_mail.from.should eql("test2@tester.com")
      
    end
    
    it "should inherit default options" do
      ParentMailer = Class.new(SailthruMailer::Base) do
        defaults do
          from("test@tester.com")
        end
      end
      ChildMailer = Class.new(ParentMailer)
      GrandChildMailer = Class.new(ChildMailer)
      ChildMailer.from.should eql "test@tester.com"
      GrandChildMailer.from.should eql "test@tester.com"
    end
    it "should send a request to sailthru" do
      t = Time.now.utc
      Time.stubs(:now).returns(t)
      SailthruMailer::Connection.any_instance.expects(:deliver).with(:complex_mail, 'dan@lifebooker.com', {}, {}, t.to_s)
      TestMailer.complex_mail("dan@lifebooker.com").deliver
    end
    context "Send options" do
      
      before(:all) do
        TestMailer.class_eval do
          def options_mail
            reply_to("myreplyaddress@test.com")
            date(Time.now + 10.days)
            to("dan@lifebooker.com")
          end
        end
      end
      
      it "should allow the user to specify send options" do
        t = Time.now
        Time.stubs(:now).returns(t)
        SailthruMailer::Connection.any_instance.expects(:deliver).with(:options_mail, 'dan@lifebooker.com', {}, {:replyto => "myreplyaddress@test.com"}, (t + 10.days).utc.to_s)
        TestMailer.options_mail.deliver
      end
      
      it "should allow us to specify test mode" do
        SailthruMailer.test = true
        TestMailer.options_mail.deliver
        SailthruMailer.deliveries.length.should eql 1
        SailthruMailer.deliveries.last.template.should eql(:options_mail)
        SailthruMailer.deliveries.last.vars.should eql({})
        SailthruMailer.test = false
      end
      
    end
    
  end
end