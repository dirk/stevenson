# Standalone test server for Stevenson. Change ":run => true" to
# ":run => false" and call `rackup config.ru` to run it through
# Rack on the front-end instead of on the back-end.

require 'rubygems'
require '../lib/stevenson'

pen do
  helpers do
    def reverse_name(name)
      name.reverse
    end
  end
  
  root(page :index)
  
  static :public => :images
  
  page :people do
    page :john
    page :jane
  end
  page :about
end