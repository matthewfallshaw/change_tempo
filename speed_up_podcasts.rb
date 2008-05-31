#!/usr/bin/env ruby

# Increase the tempo of all tracks in the 'podcasts' playlist in iTunes
# (don't double up - running this multiple times shouldn't hurt)
#
# Dependencies:
#   (you can get MacPorts from http://www.macports.org/, which'll make the port command work)
#   sudo port install soundtouch ruby rb-rubygems
#   sudo gem install activerecord activesupport rb-appscript
%w[rubygems activerecord activesupport appscript].each {|l| require l }

WORKING_DIR = '/Users/matt/.podcasts'
# Database
DB_FILE = WORKING_DIR + '/db.sqlite3'
ActiveRecord::Base.establish_connection(:adapter  => 'sqlite3',
                                        :database => DB_FILE)

# Database migration
class InitializePodcastTable < ActiveRecord::Migration
  class << self
    def up
      create_table :podcasts do |t|
        t.string :path, :null => false
        t.string :state
      end
    end
    def down
      drop_table :podcasts
    end

    def current_version
      begin
        ActiveRecord::Base.connection.select_value("SELECT version FROM schema_info").to_i
      rescue
        0
      end
    end

    def migrate_with_schema_changes_and_db(direction = :up)
      unless File.exist?(WORKING_DIR)
        FileUtils.mkdir_p(WORKING_DIR)
      end
      unless File.exist?(DB_FILE)
        cmd = "echo '' | sqlite3 '#{DB_FILE}'"
        puts cmd
        puts `#{cmd}`
      end
      unless current_version == 1
        migrate_without_schema_changes_and_db(direction)
        ActiveRecord::Base.connection.update("UPDATE schema_info SET version = 1")
      end
    end
    alias_method_chain :migrate, :schema_changes_and_db
  end
end
InitializePodcastTable.migrate(:up)

# Podcasts and conversion state
class Podcast < ActiveRecord::Base
  # lame --decode <mp3> <slow-wav>
  # soundstretch <slow-wav> <fast-wav> -tempo=+70
  # rm <slow-wav>
  # lame -h <fast-wav> <fast-mp3>
  # rm <fast-wav>
  # id3cp <mp3> <fast-mp3>
  # mv <fast-mp3> <mp3>
  # touch iTunes db for changes
end

itunes = Appscript.app("iTunes")
podcasts = itunes.playlists["podcasts"].tracks.get
