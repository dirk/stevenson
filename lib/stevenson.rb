require 'sinatra/base'
require 'haml'
require 'rack'

module Stevenson
  LIB_PATH = File.dirname(__FILE__)
  STEVIE   = LIB_PATH + '/stevenson'
  
  autoload :Application, "#{STEVIE}/application"
  autoload :Page,        "#{STEVIE}/page"
  autoload :Nest,        "#{STEVIE}/nest"
  autoload :Templates,   "#{STEVIE}/templates"
  
  autoload :Delegator,   "#{STEVIE}/delegator"
  autoload :Server,      "#{STEVIE}/server"
  
  def self.version
    @version ||= File.open(File.join(File.dirname(__FILE__), '..', 'VERSION')) { |f| f.read.strip }
  end
end

include Stevenson::Delegator