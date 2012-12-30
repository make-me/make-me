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
  end
end
