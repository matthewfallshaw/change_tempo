require File.dirname(__FILE__) + '/../spec_helper'

describe PodcastFromMp3 do

  describe "instance methods:" do
    
    it "should record path on instantiation" do
      p = PodcastFromMp3.new("path")
      p.path.should == "path"
    end
    it "should infer name from file tags" do
      p = PodcastFromMp3.new(File.join(File.dirname(__FILE__), "../fixtures/Silence.mp3"))
      p.name.should == "Shhh"
    end
    it "should infer name from file tags when file includes a space" do
      p = PodcastFromMp3.new(File.join(File.dirname(__FILE__), "../fixtures/Silence with space.mp3"))
      p.name.should == "Shhh"
    end
    it "should infer comment from file tags" do
      p = PodcastFromMp3.new(File.join(File.dirname(__FILE__), "../fixtures/Silence.mp3"))
      p.comment.should == "A comment."
    end
  end

end