def stub_download!
  Curl::Easy.stub(:download).with(anything(), anything())
end
