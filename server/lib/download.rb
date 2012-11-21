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
        file.print open(thing_url, :allow_unsafe_redirects => true).read
      end
    end

    private

    def thing_url
      url = @url

      if md = url.match(%r{tinkercad\.com/things/(\w+)-[^/]+/$})
        thing_id = md[1]
        url = "https://tinkercad.com/things/#{thing_id}/polysoup.stl"
      end

      url
    end
  end
end
