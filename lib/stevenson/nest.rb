module Stevenson
  # Abstraction of the nesting system to allow for collections to be nested in a logical, programmatic way.
  class Nest
    attr_reader :name, :parent
    
    # Constructor.
    def initialize(name, parent)
      @name = name.to_sym
      @parent = parent
      @children = []
      
      # Let the parent nest know I exist.
      @parent.child! self unless @parent.nil?
    end
    
    # Detects whether or not it is the root nest.
    def root?
      true if @parent.nil?
    end
    
    def child!(child)
      @children << child
    end
    
    def nest?
      true
    end
    
    def path(children = '')
      return children if @parent.nil? and @name == :root
      
      path = @name.to_s + '/' + children
      
      if @parent.nil?
        path
      else
        @parent.path(path)
      end
    end
  end
  
  module Nests
    autoload :Collection,  "#{STEVIE}/nests/collection"
  end
end