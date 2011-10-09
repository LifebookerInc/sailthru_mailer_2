require "active_support"
require "active_support/core_ext"
require "sailthru"

module SailthruMailer
  extend ActiveSupport::Autoload
  
  autoload :Base
  autoload :Connection
  
  mattr_accessor :settings; self.settings = {}
  mattr_accessor :test; self.test = false
  mattr_accessor :deliveries; self.deliveries = []
  
end