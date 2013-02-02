module Stevenson
  class Server
    attr_reader :app, :static_paths
    attr_accessor :run
    
    def response; @response; end
    def request;  @request;  end
    
    # Sets up the server.
    def initialize(application)
      # Will take an application and start serving pages from it.
      @app = application
      @run = run
      @static_paths = []
      
      if @app.opts[:run]
        puts "- Stevenson is writing a novel on port #{@app.opts[:port]} with ghost author #{@app.opts[:handler]}"
        
        builder = Rack::Builder.new
        builder.use Rack::CommonLogger
        @app.statics.each do |static|
          #builder.use Rack::Static, :urls => ["/css", "/images"], :root => "public"
          builder.use Rack::Static, :urls => static[:urls].collect {|p| '/' + p.to_s }, :root => static[:path].to_s
        end
        builder.run self
        @app.opts[:handler].run(
          builder.to_app,
          :Port => @app.opts[:port]
        )
        #@app.opts[:handler].run(
        #  self,
        #  :Port => 3000
        #)
        # From Sinatra, for reference:
        # handler.run self, :Host => bind, :Port => port do |server|
        #  [:INT, :TERM].each { |sig| trap(sig) { quit!(server, handler_name) } }
        #  set :running, true
        # end
      else
        puts "- Stevenson thinks he's writing a novel with the publisher Rack"
      end
    end
    
    # Rack interaction.
    def call(env)
      @request = Rack::Request.new(env)
      @response = Rack::Response.new()
      
      resp = route
      # Failsafe in case the routing layer dies.
      if resp.nil?
        [500, {}, ['Woops! Error serving file.']]
      else
        resp.to_a
      end
    end
    
    # Determines whether it's a page or a static file, then returns a response to Stevenson::Server.
    def route
      rp = request.path_info
      if rp[rp.length - 1, rp.length] == '/' and rp != '/'
        srp = rp[0, rp.length - 1]
      else
        srp = rp + '/'
      end
      
      if @app.routes.keys.include?(rp) || @app.routes.keys.include?(srp)
        p = @app.routes[rp] || @app.routes[srp]
        if content_type = p.attr(:content_type)
          response['Content-Type'] = content_type
        else
          response['Content-Type'] = 'text/html'
        end
        response.write p.call
        return response
      end
      
      #path = File.expand_path('public' + Rack::Utils.unescape(request.path_info))
      #return static!(path) if static?(path)
      
      return not_found
    end
    
    # Determine the mimetype with help from Rack. Lifted from sinatra/base.rb line 938
    def mime_type(type, value=nil)
      return type if type.nil? || type.to_s.include?('/')
      type = ".#{type}" unless type.to_s[0] == ?.
      return Rack::Mime.mime_type(type, nil) unless value
      Rack::Mime::MIME_TYPES[type] = value
    end
    
    # Check if the given path goes to a static file. Contains in-memory caching layer.
    def static? path
      # Maintain cache of files already known to be static for performance.
      return true if @static_paths.include? path
      # Otherwise hit the filesystem.
      return true if File.file? path
    end
    
    # Serve a static asset.
    def static! path
      length  = File.stat(path).size
      content = File.read(path) {|f| f.read }
      type    = mime_type(File.extname(path))
      
      response['Content-Length'] = length.to_s
      response['Content-Type'] = type
      response.write(content)
      
      response
    rescue Errno::ENOENT => e
      not_found # If for some reason we hit an error, throw up a 404.
      
      puts e.inspect # DEBUG
    end
    
    # Send a 404 response with a handy 'Not Found' message.
    def not_found
      response.status = 404
      response.write 'Not Found'
      
      response
    end
  end
end