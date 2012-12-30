require 'spec_helper'

describe MakeMe::Download do
  let(:url)  { "http://www.url.com/file.stl" }
  let(:path) { "an/output/path.stl" }

  describe "#fetch" do
    it "downloads the URL" do
      download = described_class.new(url, path)
      Curl::Easy.should_receive(:download).with(url, path)
      download.fetch
    end

    it "can translate a tinkercad thing to a download" do
      tinkercad_id = '99Ji3HC0Ukqq'
      tinkercad_url = "https://tinkercad.com/things/#{tinkercad_id}-hot-dog"
      tinkercad_download = "https://tinkercad.com/things/#{tinkercad_id}/polysoup.stl"

      download = described_class.new(tinkercad_url, path)
      Curl::Easy.should_receive(:download).with(tinkercad_download, path)
      download.fetch
    end
  end
end
