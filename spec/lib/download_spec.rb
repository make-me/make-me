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
  end
end
