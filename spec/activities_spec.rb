require_relative 'helper'
require_controller 'activities'

describe Rack::Lotus do
  before do
    # Do not render
    Rack::Lotus.any_instance.stubs(:render).returns("html")
  end

  describe "Activities Controller" do
    describe "GET /activities/:id" do
      it "should return 404 if the activity is not found" do
        Lotus::Activity.stubs(:find_by_id).returns(nil)

        get '/activities/1234abcd'
        last_response.status.must_equal 404
      end

      it "should return 200 if the activity is found" do
        Lotus::Activity.stubs(:find_by_id).returns(Lotus::Activity.new)

        get '/activities/1234abcd'
        last_response.status.must_equal 200
      end

      it "should render activities/show" do
        Lotus::Activity.stubs(:find_by_id).returns(Lotus::Activity.new)
        Rack::Lotus.any_instance.expects(:render).with(anything,
                                                       :"activities/show",
                                                       anything)

        get '/activities/1234abcd'
      end

      it "should return json when json is prioritized in accept" do
        Lotus::Activity.stubs(:find_by_id).returns(Lotus::Activity.new)

        accept "application/json"
        get '/activities/1234abcd'

        content_type.must_match "application/json"
      end

      it "should return atom when xml is prioritized in accept" do
        Lotus::Activity.stubs(:find_by_id).returns(Lotus::Activity.new)

        accept "application/xml"
        get '/activities/1234abcd'

        content_type.must_match "application/atom+xml"
      end

      it "should return atom when atom is prioritized in accept" do
        Lotus::Activity.stubs(:find_by_id).returns(Lotus::Activity.new)

        accept "application/atom+xml"
        get '/activities/1234abcd'

        content_type.must_match "application/atom+xml"
      end

      it "should return text/html by default" do
        Lotus::Activity.stubs(:find_by_id).returns(Lotus::Activity.new)

        get '/activities/1234abcd'

        content_type.must_match "text/html"
      end
    end

    describe "PUT /activities/:id" do
      it "should return 404 if the activity is not found" do
        Lotus::Activity.stubs(:find_by_id).returns(nil)

        put '/activities/1234abcd'
        last_response.status.must_equal 404
      end

      it "should return 200 if the person is found" do
        Lotus::Activity.stubs(:find_by_id).returns("something")

        put '/activities/1234abcd'
        last_response.status.must_equal 200
      end
    end
  end
end
