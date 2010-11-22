module Stevenson
  class Application
    # Every application starts with a call to :pen. This is where the journey begins.
    def self.pen(*args, &block) self.new(*args, &block); end
    def initialize(*args, &block)
      @collections = {}
      @current_collection = :root
      
      self.instance_eval &block
      
      self.run!
    end
    
    def collection(name, &block)
      @current_collection = name
      self.instance_eval &block
      @current_collection = :root
    end
    
    def page(name, block = Proc.new {})
      (@collections[@current_collection] ||= []) << Page.new(name, {:collection => @current_collection}, &block)
    end
    
    def run!(handler = Rack::Handler::Mongrel)
      puts "- Stevenson is writing a novel on port 3000 with ghost author #{handler}"
      handler.run(
        ::Stevenson::Server.new(self),
        :Port => 3000
      )
      # From Sinatra, for reference:
      # handler.run self, :Host => bind, :Port => port do |server|
      #  [:INT, :TERM].each { |sig| trap(sig) { quit!(server, handler_name) } }
      #  set :running, true
      # end
    rescue Errno::EADDRINUSE => e
      puts "Port 3000 is already in use."
    end
  end
end