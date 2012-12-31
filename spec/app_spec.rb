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

      it 'fetches all the URLs given' do
        urls = [
                  'https://tinkercad.com/things/dP2KXaBxbNw/polysoup.stl',
                  'https://tinkercad.com/things/9Ji3HC0Ukqq/polysoup.stl'
               ]
        path = MakeMe::App::FETCH_MODEL_FILE
        MakeMe::Download.should_receive(:new).with(urls, path)

        post '/print', Yajl::Encoder.encode({:url => urls})
      end
    end
  end
end
