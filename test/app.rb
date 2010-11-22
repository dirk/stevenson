require 'rubygems'
require './lib/stevenson'

# Run this until it doesn't throw an error.

puts (pen do
  collection :people do
    page :jane
    page :john
  end
  page :about
end).inspect