module MakeMe
  class Download
    def initialize(urls, output_file_basename)
      @urls, @output = urls, output_file_basename
    end

    # Downloads all the URLs passed in, and returns an array of filenames they
    # were downloaded to
    def fetch
      outputs = []
      @urls.each_with_index do |url, index|
        url = extract_tinkercad_download(url)
        file_name = "#{@output}.#{index}"
        outputs << file_name
        Curl::Easy.download(url, file_name) do |c|
          c.follow_location = true
          c.max_redirects   = 10
        end
      end
      outputs
    end

    private

    def extract_tinkercad_download(url)
      if md = url.match(%r{tinkercad\.com/things/(\w+)-[^/]+/?$})
        thing_id = md[1]
        url = "https://tinkercad.com/things/#{thing_id}/polysoup.stl"
      end

      url
    end
  end
end
