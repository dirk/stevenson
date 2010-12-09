module Stevenson
  class Application
    # Every application starts with a call to #pen. This is where the journey begins.
    class << self
      @@applications = []
      
      # Called by Stevenson::Delegator.pen. Creates and returns an instance of a Stevenson application.
      def pen(*args, &block)
        self.new(*args, &block)
      end
      # Returns an instance of Stevenson::Application by the offset. Makes life easier with Rack. (Normally you won't need offset unless you're made multiple Stevenson instances.)
      def rack(offset = 0)
        @@applications[offset].server
      end
    end
    
    
    attr_reader :routes, :server, :root
    attr_accessor :opts
    
    # Called mainly by the Stevenson::Application.pen class method. Sets up a Stevenson application.
    def initialize(*args, &block)
      #@collections = {}
      #@current_collection = :root
      @root = @current_nest = Nest.new(:root, nil)
      @routes = {}
      @opts = {}
      @helpers = []
      # Keeping a list of all the applications for Stevenson::Application.rack
      @@applications << self
      
      if args.last.is_a? Hash
        # Default options.
        @opts = {:run => true, :handler => Rack::Handler::Mongrel}.merge args.last
      end
      
      puts '- Parsing description'
      self.instance_eval &block
      
      @current_nest.each_recursive { if self.respond_to? :post_initialize; self.post_initialize; end }
      
      self.run!
    end
    
    # DSL method to define a collection. Collections allow you to group Pages without providing an "index" view. If you want an "index" view, use a #page instead.
    def collection(name, &block)
      @current_nest = Nests::Collection.new(name, @current_nest)
      #@current_collection = name
      self.instance_eval &block
      #@current_collection = :root
      @current_nest = @current_nest.parent
    end
    
    # DSL method to define a page. Now, with the new nesting syntax and the fact that a Page is a Next, a Page can have children.
    def page(name, opts = {}, &block)
      # TODO: Make this a little bit prettier.
      #@routes[((@current_collection == :root) ? '/' : ('/' + @current_collection.to_s + '/')) + name.to_s] = \
      #  ((@collections[@current_collection] ||= []) << Page.new(name, opts.merge({:collection => @current_collection}), &block)).last
      page = Page.new(name, @current_nest, self, opts)
      
      if block
        @current_nest = page
        self.instance_eval &block
        @current_nest = page.parent
      end
      
      @routes[page.route] = page
      
      puts '+ Page: ' + page.route
    end
    
    def helpers(&block)
      if block
        @helpers << block
      else
        return @helpers
      end
    end
    
    def method_missing(method, *args)
      if @root.children.collect {|c| c.name }.include? method
        @root.children.select {|c| c.name == method}.first
      else
        super(method, *args)
      end
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