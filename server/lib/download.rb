require_relative 'open-uri'

module PrintMe
  class Download
    attr_reader :url
    attr_accessor :output_file
    def initialize(url, output_file)
      @url, @output_file = url, output_file
    end

    def fetch
      open(output_file, 'wb') do |file|
        file.print open(@url, :allow_unsafe_redirects => true).read
      end
    end
  end
end
