require 'sidekiq'
require 'tmpdir'

class BuildWorker
  include Sidekiq::Worker

  def perform(working_dir, platform, commitish)
    Dir.mktmpdir("build-#{platform}-") do |build_dir|
      # TODO: sudo -D does not work
      system(*%W[sudo -D #{working_dir} python3 build.py -d #{build_dir} #{platform} image-#{platform}-#{commitish}.img])
    end

    # TODO: run a publish worker to upload the built image somewhere and post to GitHub
    # TODO: clean up afterwards
  end
end