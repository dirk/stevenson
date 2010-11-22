module Stevenson
  class Application
    # Every application starts with a call to :pen. This is where the journey begins.
    def self.pen(*args, &block) self.new(*args, &block); end
    def initialize(*args, &block)
      @collections = {}
      @current_collection = :root
      
      self.instance_eval &block
    end
    
    def collection(name, &block)
      @current_collection = name
      self.instance_eval &block
      @current_collection = :root
    end
    
    def page(name, block = Proc.new {})
      (@collections[@current_collection] ||= []) << Page.new(name, {:collection => @current_collection}, &block)
    end
  end
end