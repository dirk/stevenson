module Stevenson
  # The core of every Stevenson application is the serving of pages.
  # == Lifecycle
  # * Stevenson::Application.page method called, instantiates a new Page object.
  # * Page object reads and evaluates its own file, which creates a sequence of events executed on every page:
  # 1. <b>Describe</b>: Sets attributes, layout, content, and other "static" variables about the page.
  # 2. <b>Initialize</b>: After every page has been described, initialize is called on every page; this is when any data processing/preparation should happen.
  # 
  # == To-Do
  # * Fully implement describe-initialize system.
  # * Add functionality to allow for re-evaluation (don't need to restart the server after changing files).
  # * Refactor rendering system to make it more robust and maintainable.
  class Page < Nest
    include Stevenson::Templates
    
    attr_reader :application
    alias       :app :application
    
    attr_writer :content, :layout # Readers already defined.
    attr_reader :attrs, :attributes, :opts, :hooks
    
    # Pages are the fundamental part of Stevenson. Can be organized into collections for grouping purposes.
    def initialize(name, parent, app, opts)
      super(name, parent)
      
      @application = app
      @attrs = []; @attributes = @attrs;
      @hooks = {
        :after_initialize => []
      }
      
      @layout = @@default_layout
      @content = nil
      @opts = opts
      @render_block = nil
      
      # Inherit layout from parents.
      begin
        unless parent.layout === @@default_layout
          @layout = parent.layout
        end
      rescue NoMethodError; end
      
      # Evaluate the contents of the page file within the scope of the page.
      eval(::File.open(path!, 'r') {|f| f.read })
    end
    # Called by Stevenson::Application once the entire initialization block has run.
    def post_initialize
      @application.helpers.each do |helper|
        self.instance_eval &helper
      end
      
      @hooks[:after_initialize].each {|hook| self.instance_eval &hook }
      
      if @render_block
        self.instance_eval &@render_block
      end
    end
    
    #-- Hooks
      #++ Adds a hook that is called after the initialization sequence has run (hooks are called at the end of post_initialize).
      def after_initialize(&block)
        @hooks[:after_initialize] << block
      end
    
    # Builds upon Stevenson::Nest; adds ability to get attributes.
    def method_missing(method, *args)
      if @attrs.collect {|a| a.key }.include? method
        @attrs.select {|a| a.key === method }.first.value
      else
        super(method, *args)
      end
    end
    
    def page; self; end
    
    # Figures out where to look for the page file.
    def path!
      return @path if @path
      if @opts[:path].to_s.empty?
        if @parent.nil? # If it's the root.
          @path = ::File.expand_path('./' + @name.to_s + '.rb')
        else
          @path = ::File.expand_path(@parent.path + @name.to_s + '.rb')
        end
      else
        @path = ::File.expand_path(@opts[:path])
      end
      @path
    end
    
    # Calculates the request path to the page.
    def route
      @route ||= self.url
    end
    
    # Deprecated; not sure if it's even being used.
    def format?(path)
      warn "DEPRECATION: `format?` has been deprecated in favor of format detection in Stevenson::Page::Templates::File.\nLOCATION: #{Kernel.caller.first}"
      
      if path =~ /haml$/
        :haml
      elsif path =~ /erb$/
        :erb
      else
        :html
      end
    end
    
    # Self-explanatory; takes either a Templates::File, Templates::String, or any other object that responds to to_s.
    # The optional sub variable allows for another template to be provided for yield'ing in the templating engine.
    def render(data, sub = nil)
      if data.is_a? Templates::File or data.is_a? Templates::String
        if data.format == :erb
          p = sub ? Proc.new { render(sub) } : Proc.new { }
          return render_erb(data.content, &p)
        elsif data.format == :haml
          p = sub ? Proc.new { render(sub) } : Proc.new { }
          return Haml::Engine.new(data.content).render(self, {}, &p)
        else
          data.content
        end
      else
        # Otherwise we'll treat it as a simple string.
        return data.to_s
      end
    end
    
    # Required for ERB rendering.
    def render_erb(content, &block)
      return ERB.new(content).result binding
    end
    
    # Each page must ultimately respond to a call method, which returns an HTML file to be sent to the browser.
    # Layouts and other magic happen inside the page; the page can look up the tree into collections and so forth to infer which layout to use (eventually), but the rendering itself should happen in the page.
    def call
      return @content
    end
    
    # Allows for easy setting or getting of an attribute.
    def attr(key, value = nil)
      if value.nil? # Getter
        @attrs[key.to_sym]
      else # Setter
        @attrs[key.to_sym] = value
      end
    end
    alias :set :attr
    
    # Returns a Templates::File object for the given path.
    def file(path, format = nil)
      return Templates::File.new(self, path)
    end
    # Creates a Template::String object from a given format and string (Hint: Use some heredoc syntax).
    def inline(format, content)
      return Templates::String.new(content, format)
    end
    
    # Sets the @content variable. Returns the @content variable is no arguments passed.
    # Read the code, it's very self-explanatory.
    def content(*args)
      if args.length === 0 # Getter
        return @content
        
      elsif args.first === false # Make the page have no content
        @content = ''
        
      elsif args.first.is_a? Templates::File or args.first.is_a? Templates::String # What you should normally do
        @content = args.first
        
      elsif args.first.respond_to? :to_s # If we can at least get a string out of whatever was given.
        @content = args.first.to_s
      end
    end
    
    @@default_layout = Templates::String.new('<%= yield %>', :erb)
    # Sets/overwrites the @layout variable. Returns the @layout variable if no arguments passed.
    def layout(*args)
      if args.length === 0 # Getter
        return @layout
        
      elsif args.first === false # Make the page have no layout (just an ERB string that yields to the content).
        @layout = @@default_layout
        
      elsif args.first.is_a? Templates::File or args.first.is_a? Templates::String
        if args.first.is_a? Templates::File
          template = Templates::File.prefix(self, 'layouts/', args.first)
        else
          template = args.first
        end
        @layout = template
      end
    end
  end
end