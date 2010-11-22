require 'sinatra/base'
require 'haml'

module Stevenson
  LIB_PATH = File.dirname(__FILE__)
  STEVIE   = LIB_PATH + '/stevenson'
  
  autoload :Application, "#{STEVIE}/application"
  autoload :Page,        "#{STEVIE}/page"
  
  autoload :Delegator,   "#{STEVIE}/delegator"
  autoload :Server,      "#{STEVIE}/server"
  
  def version
    @version ||= File.open(File.join(File.dirname(__FILE__), '..', 'VERSION')) { |f| f.read.strip }
  end
end

include Stevenson::Delegator