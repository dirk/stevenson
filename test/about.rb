attr :title, 'About Stevenson'

attr :content, :erb => <<-RUBY
This is a page titled: "<%= @title %>".
RUBY