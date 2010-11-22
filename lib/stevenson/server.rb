module Stevenson
  class Server
    attr_reader :app
    def response; @response; end
    def request;  @request;  end
    
    def initialize(application)
      # Will take an application and start serving pages from it.
      @app = application
      @static_paths = []
    end
    # Stubbing out some rackety-Racks.
    def call(env)
      @request = Rack::Request.new(env)
      @response = Rack::Response.new()
      
      resp = route
      if resp.nil?
        final = [500, {}, ['Woops! Error serving file.']]
      else
        # 127.0.0.1 - - [22/Nov/2010 06:50:50] "GET / HTTP/1.1" 200 1205 0.0096
=begin
{"HTTP_HOST"=>"localhost:3000",
"SERVER_NAME"=>"localhost",
"REQUEST_PATH"=>"/test.txt",
"HTTP_USER_AGENT"=>"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.6; rv:2.0b7) Gecko/20100101 Firefox/4.0b7",
"HTTP_KEEP_ALIVE"=>"115",
"SERVER_PROTOCOL"=>"HTTP/1.1",
"SERVER_SOFTWARE"=>"Mongrel 1.1.5",
"PATH_INFO"=>"/test.txt",
"REMOTE_ADDR"=>"127.0.0.1",
"SCRIPT_NAME"=>"",
"HTTP_VERSION"=>"HTTP/1.1",
"REQUEST_URI"=>"/test.txt",
"SERVER_PORT"=>"3000",
"REQUEST_METHOD"=>"GET",
"QUERY_STRING"=>"",
"HTTP_ACCEPT_ENCODING"=>"gzip, deflate",
"HTTP_CONNECTION"=>"keep-alive",
=end
        final = resp.to_a
      end
      
      puts "#{env['HTTP_HOST']} (#{Time.now.getutc}) #{env['REQUEST_METHOD']} #{env['REQUEST_URI']} #{final.first.to_s}"
      return final
    end
    def route
      path = File.expand_path('public' + Rack::Utils.unescape(request.path_info))
      return static!(path) if static?(path)
      
      return not_found
    end
    
    def static? path
      # Maintain cache of files already known to be static for performance.
      return true if @static_paths.include? path
      # Otherwise hit the filesystem.
      return true if File.file? path
    end
    
    def static! path
      # Serving a static asset.
      length  = File.stat(path).size
      content = File.read(path) {|f| f.read }
      
      response['Content-Length'] = length.to_s
      response.write(content)
      
      response
    rescue Errno::ENOENT => e
      not_found # If for some reason we hit an error, throw up a 404.
      
      puts e.inspect # DEBUG
    end
    
    def not_found
      response.status = 404
      response.write 'Not Found'
      
      response
    end
  end
end