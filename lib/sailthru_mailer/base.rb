module SailthruMailer
  class Base
    VALID_CONFIGURATION_METHODS = [:to, :from, :cc, :bcc, :reply_to, :date]
    DEPRECATED_CONFIGURATION_METHODS = [:subject]
    CONFIGURATION_METHODS = VALID_CONFIGURATION_METHODS + DEPRECATED_CONFIGURATION_METHODS
    
    # we have accessors for
    attr_accessor :template
        
    private_class_method :new #nodoc
    
    # private initializer
    def initialize(name, *args)
      self.template = name
      self.send(name, *args)
    end
    
    # setter/getter method for each config method
    # falls back to the class method
    CONFIGURATION_METHODS.each do |m|
      class_eval <<-EOF, __FILE__, __LINE__ +1
        def #{m}(val = nil)
          @#{m} = val unless val.nil?
          @#{m} ||= self.class.#{m}
        end
      EOF
    end
    DEPRECATED_CONFIGURATION_METHODS.each do |m|
      class_eval <<-EOF, __FILE__, __LINE__ +1
        def #{m}(val = nil)
          ::ActiveSupport::Deprecation.warn("#{m} has no effect with Sailthru - please specify it in the Sailthru admin", caller(1))
          @#{m} = val unless val.nil?
          @#{m} ||= self.class.#{m}
        end
      EOF
    end
    
    # alias to as recipients for AM2 compatibility
    alias_method :recipients, :to
    
    # variables for the template
    def vars(val = nil)
      @vars = val unless val.nil?
      @vars ||= {}
    end
    def vars=(val)
      vars(val)
    end
    # we want to actually call it body for backwards compatibility
    alias_method :body, :vars
    alias_method :body=, :vars=
    
    # send the mail
    def deliver
      # handle test mode
      return SailthruMailer.deliveries << self if SailthruMailer.test
      # response = sailthru.send(template_name, email, vars, options, schedule_time)
      self.class.connection.deliver(
        self.template, 
        self.all_recipients,
        self.formatted_vars,
        self.formatted_options,
        (self.date || Time.now).utc.to_s
      )
    end
    # formatted variable hash, ready for JSON encoding
    def formatted_vars
      {}.tap do |ret|
        self.vars.each_pair do |k,v|
          ret[k] = self.prep_for_json(v)
        end
      end
    end
    protected
    # prepare a value to be converted to JSON
    def prep_for_json(val)
      val = val.collect{|v| self.prep_for_json(v)} if val.is_a?(Array)
      # recursive call for hashes
      if val.is_a?(Hash)
        val.each_pair{|k,v| val[k] = self.prep_for_json(v)} 
      # otherwise try to convert to a hash (e.g. ActiveModel)
      elsif val.respond_to?(:to_hash)
        val = self.prep_for_json(val.to_hash)
      end
      val
    end
    # get the options for this send
    def formatted_options
      {}.tap do |ret|
        ret[:replyto] = self.reply_to if self.reply_to.present?
        ret[:behalf_email] = self.from if self.from.present?
      end
    end
    # list of all email addresses
    # emails can be specified as follows
    #   to ["email1@test.com", "email2@test.com"]
    #   to "email1@test.com, email2@test.com; email3@test.com"
    #   to ["email1@test.com; email2@test.com"]
    def all_recipients
      [:to, :cc, :bcc].collect{|type| Array.wrap(self.send(type)).collect{|email| email.split(/;,/)}}.flatten.uniq.join(", ")
    end
    
    class << self
      # called when someone inherits from us
      def inherited(klass)
        VALID_CONFIGURATION_METHODS.each do |m|
          klass.send(m, self.send(m))
        end
      end
      
      def connection(reload = false)
        @connection = nil if reload
        @connection ||= SailthruMailer::Connection.new
      end
      # configuration options that can be set if a value is provided or gotten otherwise
      VALID_CONFIGURATION_METHODS.each do |m|
        class_eval <<-EOF, __FILE__, __LINE__ +1
          def #{m}(val = nil)
            @#{m} = val unless val.nil?
            @#{m}
          end
        EOF
      end
      DEPRECATED_CONFIGURATION_METHODS.each do |m|
        class_eval <<-EOF, __FILE__, __LINE__ +1
          def #{m}(val = nil)
            ::ActiveSupport::Deprecation.warn("#{m} has no effect with Sailthru - please specify it in the Sailthru admin", caller(5))
            @#{m} = val unless val.nil?
            @#{m}
          end
        EOF
      end
      # alias to as recipients for AM2 compatibility
      alias_method :recipients, :to
      
      protected
      # just here to give us nicer syntax
      def defaults(vals = nil, &block)
        return instance_exec(&block) if block_given?
        vals.each_pair{|k,v| self.send(k, v)}
      end
      # if this is a valid public instance method, we proceed
      def method_missing(m, *args, &block)
        if self.action_defined?(m)
          return new(m, *args)
        else
          return super
        end
      end
      # 
      def action_defined?(m)
        self.public_instance_methods.map(&:to_sym).include?(m.to_sym)
      end
    end
    
  end
end
