module Stevenson
  # Abstractions of string and files to allow for referenced (files) and inline (string) templating.
  module Templates
    # Abstracts a string into standardized attributes: format and content.
    class String
      attr_accessor :format, :content

      def initialize(content, format)
        @content = content; @format = format
      end
    end

    # Abstracts a file into standardized attributes: path, format, and content.
    class File
      attr_accessor :path, :format, :original_path, :page

      def self.prefix(page, prefix, old)
        self.new(page, prefix + old.original_path, old.format)
      end
      def initialize(page, path, format = nil, content = nil)
        @page = page

        if format
          @format = format.to_sym
        else
          if path =~ /\.haml$/
            @format = :haml
          elsif path =~ /\.erb$/
            @format = :erb
          elsif path =~ /\.md$/ or path =~ /\.markdown$/
            @format = :markdown
          else
            @format = :html
          end
        end

        @original_path = path

        # ::File.expand_path('./') + (path.slice(0,1) === '/' ? '' : '/') + path
        base_path = ::File.expand_path('./') + '/' + path
        if @page.parent.nil?
          page_path = ::File.expand_path('./') + '/' + path
        else
          page_path = ::File.expand_path('./') + '/' + @page.parent.path + path
        end

        if ::File.file?(page_path)
          @path = page_path
        else
          @path = base_path
        end
      end
      def content
        #if ::File.file?(path)
          #@content ||= ::File.open(path, 'r') {|f| f.read }
          ::File.open(path, 'r') {|f| f.read }
        #end
      end
    end
  end
end