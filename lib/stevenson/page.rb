module Stevenson
  class Page
    # Pages are the fundamental part of Stevenson. Can be organized into collections for grouping purposes.
    def initialize(name, opts)
      @name = name
      @collection = opts[:collection]
    end
    
    def call
      # Each page must ultimately respond to a call method, which returns an HTML file to be sent to the browser.
      # Layouts and other magic happen inside the page; the page can look up the tree into collections and so forth to infer layout to use, but the rendering itself should happen in the page.
    end
    
    # Utility methods for actually rendering the page, like :attr, :content, :layout and so forth go in here.
  end
end