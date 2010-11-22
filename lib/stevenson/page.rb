module Stevenson
  class Page
    # Pages are the fundamental part of Stevenson. Can be organized into collections for grouping purposes.
    def initialize(name, opts)
      @name = name
      @collection = opts[:collection]
      @attrs = []; @attributes = @attrs;
      @content = ''; @content_opts = {}
      @opts = opts
      
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
    
    def format?(path)
      if path =~ /haml$/
        :haml
      elsif path =~ /erb$/
        :erb
      else
        :html
      end
    end
    def render(data)
      if data.is_a? Hash
        # Figure out whether we should grab a file or render an inline template.
        # rc = render-content
        if data[:path].to_s.empty?
          rc = data[:body]
          format = data[:format]
        else
          rc = File.read(data[:path]) {|f| f.read }
          format = format? data[:path]
        end
        
        if format == :erb
          return ERB.new(rc).result binding
        elsif format == :haml
          Haml::Engine.new(rc).render self
        else
          rc
        end
      else
        # Otherwise we'll treat it as a simple string.
        return data.to_s
      end
    end
    
    def call
      # Each page must ultimately respond to a call method, which returns an HTML file to be sent to the browser.
      # Layouts and other magic happen inside the page; the page can look up the tree into collections and so forth to infer layout to use, but the rendering itself should happen in the page.
      
      if @content_opts[:layout].to_s.empty?
        @layout = '{yield}'
      else
        @layout = render(@content_opts[:layout])
      end
      
      if @content_opts.has_key? :erb
        @content = @layout.sub('{yield}', render(@content_opts[:erb]))
      end
      
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
        value
      end
      alias :v :to_s
      alias :value :to_s
    end
    
    # Allows for easy setting or getting of an attribute.
    def attr(key, *args)
      if args.length == 0
        @attrs.select {|a| a.key == key.to_sym }.first
      else
        opts = (args.length == 2) ? args[1] : {}
        @attrs << Attribute.new(self, key.to_sym, args[0], args[1])
      end
    end
    
    # Right now just accepts a content definition.
    def content(opts = {})
      @content_opts = opts
    end
    
    # Grab the contents of a file within the directory of the path (/ for :root collection, for example)
    def file(path = '')
      basepath = (@collection == :root) ? File.expand_path('./') : File.expand_path(@collection.to_s + '/')
      return {:path => basepath + '/' + path}
    end
    def layout(path = '')
      return {:path => File.expand_path('layouts/' + path)}
    end
  end
end