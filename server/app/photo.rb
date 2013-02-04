module MakeMe
  class App
    IMAGESNAP = File.join(APP_ROOT, 'vendor', 'imagesnap', 'imagesnap')

    get '/photo.json' do
      out_dir = settings.public_folder
      count = 0
      images = cameras.map do |camera|
        out_name = "snap_#{count += 1}_#{Time.now.to_i}.jpg"
        Process.wait Process.spawn(*[IMAGESNAP, '-d', camera.strip, File.join(out_dir, out_name)])
        "http#{request.secure? ? 's' : ''}://#{request.host_with_port}/#{out_name}"
      end

      content_type :json
      Yajl::Encoder.encode({:images => images})
    end

    get '/photo' do
      out_name = 'snap_' + Time.now.to_i.to_s + ".jpg"
      out_dir = settings.public_folder

      # Pick one safely and use it
      cams = cameras
      camera = params[:camera] || Random.rand(cams.length)
      camera = cams[camera.to_i % cams.length].strip
      Process.wait Process.spawn(*[IMAGESNAP, '-d', camera, File.join(out_dir, out_name)])

      redirect out_name
    end

    helpers do
      def cameras
        IO.popen([IMAGESNAP, "-l"]) do |cameras|
          cameras.readlines
        end[1..-1]
      end
    end

  end
end
