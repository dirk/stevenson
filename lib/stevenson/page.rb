module Stevenson
  class Page < Nest
    attr_reader :application
    alias       :app :application
    
    attr_writer :content, :layout # Readers already defined.
    attr_reader :attrs, :attributes, :opts, :hooks
    
    # Pages are the fundamental part of Stevenson. Can be organized into collections for grouping purposes.
    def initialize(name, parent, app, opts)
      super(name, parent)
      
      @attrs = []; @attributes = @attrs;
      @content = nil
      @opts = opts
      @layout = inline(:erb, '<%= yield %>')
      @application = app
      @hooks = {
        :after_initialize => []
      }
    end
    # Called by Stevenson::Application once the entire initialization block has run.
    def post_initialize
      @application.helpers.each do |helper|
        self.instance_eval &helper
      end
      
      # Evaluate the contents of the page file within the scope of the page.
      eval(File.read(path!) {|f| f.read })
      
      @hooks[:after_initialize].each {|hook| self.instance_eval &hook }
    end
    
    # Hooks
      
      # Adds a hook that is called after the initialization sequence has run (hooks are called at the end of post_initialize).
      def after_initialize(&block)
        @hooks[:after_initialize] << block
      end
    
    #
    def method_missing(method, *args)
      if @attrs.collect {|a| a.key }.include? method
        @attrs.select {|a| a.key === method }.first.value
      else
        super(method, *args)
      end
    end
    
    # Figures out where to look for the page file.
    def path!
      return @path if @path
      if @opts[:path].to_s.empty?
        collection_path = @parent.path
        #puts Dir[File.expand_path(collection_path + @name.to_s + '.*')].inspect
        @path = File.expand_path(collection_path + @name.to_s + '.rb')
      else
        #puts File.expand_path(@opts[:path])
        @path = File.expand_path(@opts[:path])
      end
      @path
    end
    
    # Calculates the request path to the page.
    def route
      @route ||= '/' + @parent.path + @name.to_s
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
    
    
    
    # Utility methods for actually rendering the page, like `attr`, `content`, `layout` and so forth.
    
    # Allows for the storage of options within an attribute.
    class Attribute
      attr_accessor :key, :value, :opts
      attr_reader :parent
      
      def initialize(parent, key, value, opts)
        @parent = parent; @key = key; @value = value; @opts = opts
      end
      # Expose the value of the attribute. (Aliased as :v and :value.)
      def to_s
        @value
      end
      alias :v :to_s
      alias :value :to_s
    end
    
    # Abstractions of string and files to allow for referenced (files) and inline (string) templating.
    module Templates
      # Abstracts a string into standardized attributes: format and content.
      class String
        attr_accessor :format, :content
        
        def initialize(content, format)
          @content = content; @format = format
        end
      end
      
      # Abstracts a file into standardized attributes: path, format, and content.
      class File
        attr_accessor :path, :format, :original_path
        
        def self.prefix(prefix, old)
          self.new(prefix + old.original_path, old.format)
        end
        def initialize(path, format = nil, content = nil)
          if format
            @format = format.to_sym
          else
            if path =~ /haml$/
              @format = :haml
            elsif path =~ /erb$/
              @format = :erb
            else
              @format = :html
            end
          end
          
          @original_path = path
          @path = ::File.expand_path('./') + (path.slice(0,1) === '/' ? '' : '/') + path
        end
        def content
          if ::File.file?(path)
            @content ||= ::File.read(path) {|f| f.read }
          else
            ''
          end
        end
      end
    end
    
    # Allows for easy setting or getting of an attribute. Considering throwing in method_missing for getting.
    def attr(key, *args)
      if args.length == 0 # Getter
        @attrs.select {|a| a.key == key.to_sym }.first
        
      else # Setter
        opts = (args.length === 2) ? args[1] : {}
        @attrs << Attribute.new(self, key.to_sym, args[0], args[1])
      end
    end
    alias :set :attr
    
    # Returns a Templates::File object for the given path.
    def file(path, format = nil)
      # Old-age functionality that included auto-calculated prefixes.
      #basepath = (@collection == :root) ? File.expand_path('./') : File.expand_path(@collection.to_s + '/')
      #path = basepath + '/' + path
      #return Templates::File.new((@collection === :root ? '' : @collection.to_s + '/') + path)
      
      # New-age simplicity.
      return Templates::File.new(path)
    end
    # Creates a Template::String object from a given format and string (Hint: Use some heredoc syntax).
    def inline(format, content)
      return Templates::String.new(content, format)
    end
    
    # Tells it what to render for the content of the page. Returns the @content variable is no arguments passed.
    # If given a Templates::File or Templates::String, it will defer rendering until after initialization.
    # 
    # TODO: Make this more reusable, extensible, and DRY.
    def content(*args)
      if args.length === 0
        return @content
      elsif args.first === false
        @content = ''
      elsif args.first.is_a? Templates::File or args.first.is_a? Templates::String
        self.after_initialize do
          @content = render(@layout, args.first)
        end
      elsif args.first.respond_to? :to_s
        @content = args.first.to_s
      end
    end
    
    # Sets/overwrites the @layout variable. Returns the @layout variable if no arguments passed.
    def layout(*args)
      if args.length === 0
        return @layout
      elsif args.first === false
        @layout = inline(:erb, '<%= yield %>')
      elsif args.first.is_a? Templates::File or args.first.is_a? Templates::String
        if args.first.is_a? Templates::File
          template = Templates::File.prefix('layouts/', args.first)
        else
          template = args.first
        end
        @layout = template
      end
    end
  end
end