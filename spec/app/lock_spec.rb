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

      app.any_instance.should_receive(:lock_data).
                       with(:json => true).
                       and_return('data')
      get '/lock'
      expect(last_response.body).to eq('data')
    end
  end

  def auth
    authorize 'hubot', 'isalive'
  end
end
