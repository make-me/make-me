require 'spec_helper'

describe MakeMe::App do
  describe 'POST /print' do
    it 'requires basic auth' do
      post '/print'
      expect(last_response.status).to eq(401)
      auth
      post '/print'
      expect(last_response.status).to_not eq(401)
    end

    context 'when authed and unlocked' do
      before do
        auth
        app.any_instance.stub(:locked? => false)
        app.any_instance.stub(:lock!)
      end

      let(:urls) {[
                    'https://tinkercad.com/things/dP2KXaBxbNw/polysoup.stl',
                    'https://tinkercad.com/things/9Ji3HC0Ukqq/polysoup.stl'
                  ]}

      it 'fetches all the URLs given' do
        path = MakeMe::App::FETCH_MODEL_FILE
        download = mock('download')
        download.should_receive(:fetch)
        MakeMe::Download.should_receive(:new).with(urls, path).and_return(download)

        post '/print', Yajl::Encoder.encode({:url => urls})
      end

      it 'normalizes with the given params' do
        stub_download!
        inputs = MakeMe::Download.new(urls, MakeMe::App::FETCH_MODEL_FILE).fetch
        output = MakeMe::App::CURRENT_MODEL_FILE
        scale  = 0.5
        count  = 12
        normalizer = mock('normalizer')

        normalizer.should_receive(:normalize!).and_return(true)
        MakeMe::Normalizer.should_receive(:new).
                           with(inputs, output, {:scale => scale, :count => count}).
                           and_return(normalizer)
        post '/print', Yajl::Encoder.encode({:url => urls, :scale => scale, :count => count})
      end
    end
  end
end
