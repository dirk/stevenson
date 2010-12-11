describe do
  attr :name, 'Jane Smith'
  attr :title, 'People / Jane Smith'
  
  content file('jane_smith.erb')
end

act do
  @siblings = parent.children.select {|c| c != self }.collect {|c| c.name.to_s }.join(', ')
end