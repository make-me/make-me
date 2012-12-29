module MakeMe
  class Download
    attr_reader :url
    attr_accessor :output_file

    def initialize(url, output_file)
      @url, @output_file = url, output_file
    end

    def fetch
      Curl::Easy.download(thing_url, output_file) do |c|
        c.follow_location = true
        c.max_redirects   = 10
      end
    end

    private

    def thing_url
      url = @url

      if md = url.match(%r{tinkercad\.com/things/(\w+)-[^/]+/?$})
        thing_id = md[1]
        url = "https://tinkercad.com/things/#{thing_id}/polysoup.stl"
      end

      url
    end
  end
end
