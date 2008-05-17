#!/usr/bin/env ruby

# Dependencies:
#   sudo port install soundtouch
%w[rubygems activerecord activesupport].each {|l| require l }

# Database
ActiveRecord::Base.establish_connection(:adapter  => 'mysql',
                                        :database => 'podcasts',
                                        :username => 'root',
                                        :password => '',
                                        :host     => 'localhost')

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
      ActiveRecord::Base.connection.select_value("SELECT version FROM schema_info").to_i
    end

    def migrate_with_schema_changes(direction = :up)
      unless current_version == 1
        migrate_without_schema_changes(direction)
        ActiveRecord::Base.connection.update("UPDATE schema_info SET version = 1")
      end
    end
    alias_method_chain :migrate, :schema_changes
  end
end
InitializePodcastTable.migrate(:up)

# Podcasts and conversion state
class Podcast < ActiveRecord::Base
  # export ID3 tags
  # lame --decode <mp3> <slow-wav>
  # soundstretch <slow-wav> <fast-wav> -tempo=+70
  # rm <slow-wav>
  # lame -h <fast-wav> <fast-mp3>
  # rm <fast-wav>
  # id3cp <mp3> <fast-mp3>
  # mv <fast-mp3> <mp3>
  # touch iTunes db for changes
end
