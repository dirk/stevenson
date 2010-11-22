# Example way to use a Rackup file.
# You must use "pen :run => false do ..." inside the app.rb file for Rackup to work properly.

require 'app'

run Stevenson::Application.rack