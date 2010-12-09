attr :name, 'Jane Smith'
attr :title, 'People / Jane Smith'

after_initialize do
  @siblings = parent.children.select {|c| c != self }.collect {|c| c.name.to_s }.join(', ')
end

content file('jane_smith.erb')