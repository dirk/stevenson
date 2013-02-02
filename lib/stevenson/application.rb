require 'optparse'



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
    
    
    attr_reader :routes, :server, :opts
    attr_accessor :statics
    
    def parse_options!
      @to_do = false
      @opts = {:run => true, :handler => Rack::Handler::Mongrel, :port => 3000, :verbose => true, :production => false}
      
      OptionParser.new do |opts|
        opts.banner = <<HELP
stevenson, a tool for building static sites.

Available commands:
HELP
        
        opts.on('-b', '--build', "Generates a static site in the output directory") do
          @to_do = 'build'
        end
        
        opts.on('-r', '-s', '--run', '--serve', '--server', 'Use a web server') do |v|
          @to_do = 'run'
        end
        
        opts.on('-p [PORT]', 'Port (when using web server)') do |p|
          @opts[:port] = p.to_i
        end
        
        opts.on('--production', 'Toggle whether or not to run in production mode (build only)') do
          @opts[:production] = true
        end
        
        opts.on('-s', 'Silence logging') do
          @opts[:verbose] = false
        end
        
        opts.on('--version', '-v', '-V', "Version") do |v|
          puts "Stevenson "+Stevenson.version
          exit 0
        end
        
        #opts.on('--echo [ECHO]', "Echo") do |e|
        #  puts e.inspect
        #end
      end.parse!
    end
    
    # Called mainly by the Stevenson::Application.pen class method. Sets up a Stevenson application.
    def initialize(*args, &block)
      self.parse_options!
      
      print '- Stevenson ' + Stevenson.version + ' loading...' if opts[:verbose]
      @root = @current_nest = Nest.new(:root, nil)
      @base = ''
      @routes = {}
      @helpers = []
      @statics = []
      # Keeping a list of all the applications for Stevenson::Application.rack
      @@applications << self
      
      if args.last.is_a? Hash
        # Default options.
        @opts = @opts.merge args.last
      end
      
      print " done\n" if opts[:verbose]
      puts '- Parsing description' if opts[:verbose]
      self.instance_eval &block
      
      @current_nest.each_recursive { if self.respond_to? 'act!'.to_sym; self.act!; end }
      
      
      if @to_do == 'build'
        self.build!
      elsif @to_do == 'run'
        self.run!
      else
        
      end
    end
    
    def base(name = false)
      if name
        @base = name
      end
      @base
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
      
      @routes[page.route] = page
      
      puts '+ Page: ' + page.route if opts[:verbose]
      
      if block
        @current_nest = page
        self.instance_eval &block
        @current_nest = page.parent
      end
      
      return page
    end
    
    def production?
      @opts[:production]
    end
    
    def root(p = nil)
      if p.is_a? Stevenson::Page
        @root = p
        @current_nest = p
        p.parent = nil
      elsif p === nil
        return @root
      else
        raise Exception.new('Unrecognized object')
      end
    end
    
    def static(statics)
      statics.each do |key, value|
        unless value.is_a? Array
          value = [value]
        end
        @statics << {:path => key, :urls => [value].flatten}
      end
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
    
    def build!
      puts '- Building static site' if opts[:verbose]
      
      puts '- Flushing old output directory' if opts[:verbose]
      # Clean everything up
      FileUtils.rm_rf './output'
      FileUtils.mkdir './output'
      
      puts '- Writing routes' if opts[:verbose]
      self.routes.each_pair do |path, route|
        dir = ''
        
        path = path.slice(1, path.length)
        unless route.attr(:path)
          dir = path
          if path == ''
            path = 'index.html'
          elsif path.ends_with?('/')
            path += 'index.html'
          else
            path += '/index.html'
          end
        else
          parts = path.split('/')
          dir = (parts.slice(0, parts.length - 1) || []).join('/')
        end
          
        if dir.length > 0
          puts "+ Directory: #{dir}" if opts[:verbose]
          FileUtils.mkdir_p "./output/#{dir}"
        end
        
        puts "+ Page: #{path}" if opts[:verbose]
        File.open("./output/#{path}", 'w') {|f| f.write(route.call) }
        
        #puts route.call.inspect
      end
      
      puts '- Copying static assets' if opts[:verbose]
      self.statics.each do |static|
        static[:urls].each do |dir|
          orig_base = "./#{static[:path]}/#{dir}"
          dest_base = "./output#{@base}/#{dir.to_s}"
          
          FileUtils.mkdir_p dest_base
          
          directories = []; files = []
          Dir["#{orig_base}/**/*"].each do |item|
            if File.directory? item
              directories << item
            elsif File.file? item
              files << item
            end
          end
          
          directories.each do |directory|
            FileUtils.mkdir_p dest_base + directory.slice(orig_base.length, directory.length)
          end
          files.each do |file|
            source = file
            dest   = dest_base + file.slice(orig_base.length, file.length)
            
            FileUtils.cp source, dest
          end
        end
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