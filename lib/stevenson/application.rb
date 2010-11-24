module Stevenson
  class Application
    # Every application starts with a call to :pen. This is where the journey begins.
    class << self
      @@applications = []
      
      # Called by the :pen method in Stevenson::Delegate. Creates and returns an instance of a Stevenson application.
      def pen(*args, &block)
        self.new(*args, &block)
      end
      # Returns an instance of Stevenson::Application by the offset. Makes life easier with Rack.
      def rack(offset = 0)
        @@applications[offset].server
      end
    end
    
    
    attr_reader :routes, :server
    attr_accessor :opts
    
    # Called mainly by the :pen class method in Stevenson::Application. Sets up a Stevenson application.
    def initialize(*args, &block)
      @collections = {}
      @current_collection = :root
      @routes = {}
      @opts = {}
      # Keeping a list of all the applications for Stevenson::Application.rack
      @@applications << self
      
      if args.last.is_a? Hash
        # Default options.
        @opts = {:run => true, :handler => Rack::Handler::Mongrel}.merge args.last
      end
      
      puts '- Parsing description'
      self.instance_eval &block
      
      self.run!
    end
    
    # DSL method to define a collection.
    def collection(name, &block)
      @current_collection = name
      self.instance_eval &block
      @current_collection = :root
    end
    
    # DSL method to define a page.
    def page(name, opts = {}, block = Proc.new {})
      # TODO: Make this a little bit prettier.
      puts '+ Page: ' + @current_collection.to_s + '/' + name.to_s
      @routes[((@current_collection == :root) ? '/' : ('/' + @current_collection.to_s + '/')) + name.to_s] = \
        ((@collections[@current_collection] ||= []) << Page.new(name, opts.merge({:collection => @current_collection}), &block)).last
    end
    
    # Attempts to instantiate an instance of Stevenson::Server
    # Server either instantiates a Rack instance and hooks itself up to Rack,
    # or makes itself available to be hooked up to Rack).
    def run!
      return (@server = Stevenson::Server.new(self))
    rescue Errno::EADDRINUSE => e
      puts "Port 3000 is already in use."
    end
  end
end