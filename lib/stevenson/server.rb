module Stevenson
  class Server
    def initialize(application)
      # Will take an application and start serving pages from it.
    end
    # Stubbing out some rackety-Racks
    def call(env)
      return [200, {}, ['A monster is rising...']]
    end
  end
end