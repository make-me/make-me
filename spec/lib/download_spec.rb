require 'spec_helper'

describe MakeMe::Download do
  let(:path) { "an/output/path.stl" }

  describe "#fetch" do
    it "downloads all the URLs given" do
      url_count = 3
      urls = ["http://www.url.com/file.stl"] * url_count

      download = described_class.new(urls, path)
      urls.each_with_index do |url, index|
        Curl::Easy.should_receive(:download).with(url, "#{path}.#{index}")
      end
      download.fetch
    end

    it "can translate a tinkercad thing to a download" do
      tinkercad_id = '99Ji3HC0Ukqq'
      tinkercad_url = "https://tinkercad.com/things/#{tinkercad_id}-hot-dog"
      tinkercad_download = "https://tinkercad.com/things/#{tinkercad_id}/polysoup.stl"
      download_path = "#{path}.0"

      download = described_class.new([tinkercad_url], path)
      Curl::Easy.should_receive(:download).with(tinkercad_download, download_path)
      download.fetch
    end
  end
end
