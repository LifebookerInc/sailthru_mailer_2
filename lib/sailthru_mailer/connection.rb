module SailthruMailer
  class Connection
    def initialize
      @client = Sailthru::SailthruClient.new(
        SailthruMailer.settings[:api_key],
        SailthruMailer.settings[:api_secret],
        SailthruMailer.settings[:api_url]
      )
    end
    def deliver(*args)
      @client.send(*args)
    end
    # proxy all methods to @client
    def method_missing(m, *args, &block)
      @client.__send__(m, *args, &block)
    end
  end
end