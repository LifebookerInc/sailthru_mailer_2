require "active_support"
require "active_support/core_ext"
require "sailthru"
require 'sailthru_mailer/base'
require 'sailthru_mailer/connection'

module SailthruMailer

  mattr_accessor :settings; self.settings = {}
  mattr_accessor :test; self.test = false
  mattr_accessor :deliveries; self.deliveries = []
  
end