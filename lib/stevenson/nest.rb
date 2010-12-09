module Stevenson
  # Abstraction of the nesting system to allow for collections to be nested in a logical, programmatic way.
  class Nest
    attr_reader :name, :children
    attr_writer :parent
    
    # Constructor; arguments should be self-explanatory.
    def initialize(name, parent)
      @name = name.to_sym
      @parent = parent
      @children = []
      
      # Let the parent nest know I exist.
      @parent.child! self unless @parent.nil?
    end
    
    # Searches for children with a name matching the method; then falls back to throwing errors.
    def method_missing(method, *args)
      if @children.collect {|c| c.name }.include? method
        @children.select {|c| c.name === method }.first
      else
        super(method, *args)
      end
    end
    
    # Detects whether or not it is the root nest.
    def root?
      true if @parent.nil?
    end
    
    # Called by a child to notify the parent of its presence.
    def child!(child)
      @children << child
    end
    
    # Pass a block to be executed for each of the Nest's children.
    def each
      @children.each do |child|
        yield child
      end
    end
    
    # Returns the parent; if a name is given, it will look through all of the parents for the parent with the name.
    def parent(name = nil)
      # ^ It's moments like these that I wish Ruby was Erlang.
      if name
        self.parents.select {|p| p.name.to_sym === name.to_sym }.first
      else
        @parent
      end
    end
    
    # Assembles an array of the Nest's parents.
    def parents
      parents = []
      s = self
      while p = s.parent
        parents << p
        s = p
      end
      return parents
    end
    
    def nest?
      true
    end
    
    # Runs a block for this Nest, then calls each on all of its parents.
    def each_recursive(&block)
      self.instance_eval &block
      
      @children.each do |child|
        child.each_recursive &block
      end
    end
    
    # Recursively calculates the path to this node (climbs up the parents).
    # Returns a path like "one/two/three/"
    def path(children = '')
      return children if @parent.nil?
      
      path = @name.to_s + '/' + children
      
      if @parent.nil?
        path
      else
        @parent.path(path)
      end
    end
    # Returns...
    def url(children = [])
      unless @name === :root or @name === :index
        children << name.to_s
      end
      
      if @parent.nil?
        '/' + children.reverse.join('/')
      else
        @parent.url(children)
      end
    end
  end
  
  module Nests
    autoload :Collection,  "#{STEVIE}/nests/collection"
  end
end