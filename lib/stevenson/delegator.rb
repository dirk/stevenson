module Stevenson
  module Delegator
    def pen(*args, &block)
      ::Stevenson::Application.pen(*args, &block)
    end
=begin
    # Lifted from Sinatra. Only need it to throw the :pen method into the current scope (look at lib/stevenson.rb).
    def self.delegate(*methods)
      methods.each do |method_name|
        eval <<-RUBY, binding, '(__DELEGATOR__)', 1
          def #{method_name}(*args, &b)
            ::Stevenson::Application.send(#{method_name.inspect}, *args, &b)
          end
          private #{method_name.inspect}
        RUBY
      end
    end

    delegate :pen
=end
  end
end