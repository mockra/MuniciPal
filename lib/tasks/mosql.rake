# This is a simplified version of what we're using in production for drinksoma.com

namespace :mosql do
  task :run => :environment do
    conf_path = Rails.root.join('config', 'tweets.yaml')
    cmd = "mosql -c #{conf_path} --sql #{ENV['DATABASE_URL']} --mongo #{ENV['MONGOLAB_URI']}"

    IO.popen(cmd) do |child|
      trap('TERM') { Process.kill 'INT', child.pid }
      $stdout.sync = true
      while line = child.gets
        puts line
      end
      puts child.read
    end
  end
end
