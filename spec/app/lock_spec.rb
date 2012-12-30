require 'spec_helper'

describe 'MakeMe::App Lock' do
  describe 'GET /lock' do
    it 'requires basic auth' do
      get '/lock'
      expect(last_response.status).to eq(401)
      auth
      get '/lock'
      expect(last_response.status).to eq(200)
    end

    it 'responds with the lock data when locked' do
      app.any_instance.stub(:locked? => true)
      auth

      app.any_instance.should_receive(:lock_data).and_return('data')
      get '/lock'
      expect(last_response.body).to eq('data')
    end
  end

  describe 'DELETE /lock' do
    it 'requires basic auth' do
      delete '/lock'
      expect(last_response.status).to eq(401)
      auth
      delete '/lock'
      expect(last_response.status).to_not eq(401)
    end

    context "when user is authed and app is locked" do
      before do
        auth
        app.any_instance.stub(:locked? => true)
      end

      it 'unlocks if the printer is not printing' do
        File.stub(:exist?).with(MakeMe::App::PID_FILE).and_return(false)
        MakeMe::Lock.any_instance.should_receive(:unlock!)
        delete '/lock'
      end

      it 'returns 200 if it unlocks' do
        File.stub(:exist?).with(MakeMe::App::PID_FILE).and_return(false)
        delete '/lock'
        expect(last_response.status).to eq(200)
      end
    end
  end

  def auth
    authorize 'hubot', 'isalive'
  end
end
