%w[ spec rubygems ruby-debug ]
require File.join(File.dirname(__FILE__), '../speed_up_podcasts')

describe Podcast do
  it "should be valid" do
    p = Podcast.new

    p.should be_valid
  end
end
