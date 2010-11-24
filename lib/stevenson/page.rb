module Stevenson
  class Page
    # Pages are the fundamental part of Stevenson. Can be organized into collections for grouping purposes.
    def initialize(name, opts)
      @name = name
      @collection = opts[:collection]
      @attrs = []; @attributes = @attrs;
      @content = nil
      @opts = opts
      @layout = '{yield}'
      
      # Evaluate the contents of the page file within the scope of the page.
      eval(File.read(path) {|f| f.read })
    end
    
    # Figures out where to look for the page file.
    def path
      return @path if @path
      if @opts[:path].to_s.empty?
        collection_path = (@collection == :root) ? '' : (@collection.to_s + '/')
        #puts Dir[File.expand_path(collection_path + @name.to_s + '.*')].inspect
        @path = File.expand_path(collection_path + @name.to_s + '.rb')
      else
        #puts File.expand_path(@opts[:path])
        @path = File.expand_path(@opts[:path])
      end
      @path
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
    def render(data)
      if data.is_a? Templates::File or data.is_a? Templates::String
        if data.format == :erb
          return ERB.new(data.content).result binding
        elsif data.format == :haml
          return Haml::Engine.new(data.content).render self
        else
          data.content
        end
      else
        # Otherwise we'll treat it as a simple string.
        return data.to_s
      end
    end
    
    def call
      # Each page must ultimately respond to a call method, which returns an HTML file to be sent to the browser.
      # Layouts and other magic happen inside the page; the page can look up the tree into collections and so forth to infer layout to use, but the rendering itself should happen in the page.
      return @content
    end
    
    
    
    # Utility methods for actually rendering the page, like :attr, :content, :layout and so forth go in here.
    
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
        attr_accessor :path, :format, :content, :original_path
        
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
          if ::File.file?(path)
            @content = ::File.read(path) {|f| f.read }
          end
        end
      end
    end
    
    # Allows for easy setting or getting of an attribute. Considering throwing in method_missing for getting.
    def attr(key, *args)
      if args.length == 0
        @attrs.select {|a| a.key == key.to_sym }.first
      else
        opts = (args.length == 2) ? args[1] : {}
        @attrs << Attribute.new(self, key.to_sym, args[0], args[1])
      end
    end
    
    # Grab the contents of a file within the directory of the path (/ for :root collection, for example)
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
    
    # Tells it what to render for the content of the page.
    def content(*args)
      if args.first === false
        @content = ''
      elsif args.first.is_a? Templates::File or args.first.is_a? Templates::String
        @content = @layout.sub('{yield}', render(args.first))
      end
    end
    # Sets/overwrites the @layout variable.
    def layout(*args)
      if args.first === false
        @layout = '{yield}'
      elsif args.first.is_a? Templates::File or args.first.is_a? Templates::String
        if args.first.is_a? Templates::File
          template = Templates::File.prefix('layouts/', args.first)
        else
          template = args.first
        end
        @layout = render(template)
      end
    end
  end
end