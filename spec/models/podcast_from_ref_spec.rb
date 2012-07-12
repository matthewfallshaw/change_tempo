require File.dirname(__FILE__) + '/../spec_helper'

describe PodcastFromRef do

  describe "class methods:" do

    it "should have a playlist accessor" do
      PodcastFromRef.playlist = "some playlist"
      PodcastFromRef.playlist.should == "some playlist"
    end
    it "should have a playlist_count" do
      PodcastFromRef.stub!(:all_podcast_refs).and_return([1,2,3])

      PodcastFromRef.playlist_count.should == 3
    end
    it "should process playlists"

  end

  describe "instance methods:" do
    
    it "should infer path from location" do
      ref = mock("podcast_ref").as_null_object
      p = PodcastFromRef.new(ref)
      
      p.should_receive(:location).and_return(mock("location").as_null_object)
      
      p.path
    end
    it "should infer location from ref" do
      ref = mock("podcast_ref").as_null_object
      p = PodcastFromRef.new(ref)
      
      ref.should_receive(:location)
      
      p.location
    end
    [:name, :comment].each do |prop|
      it "should infer #{prop} from ref" do
        ref = mock("podcast_ref").as_null_object
        p = PodcastFromRef.new(ref)

        ref.should_receive(prop).and_return(mock("getter").as_null_object)

        p.send(prop)
      end
    end
  end

end
