# Standalone test server for Stevenson. Change ":run => true" to
# ":run => false" and call `rackup config.ru` to run it through
# Rack on the front-end instead of on the back-end.

require 'rubygems'
require '../lib/stevenson'

pen :run => true do
  helpers do
    def test
      'testing'
    end
  end
  
  page :people do
    page :john
  end
  page :about
  
end

# Currently makes routes to "/about" and "/people/john".