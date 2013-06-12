require_relative 'helper'
require_controller 'authors'

class  Lotus::Author; end
module Lotus;  end

describe Rack::Lotus do
  before do
    # Do not render
    Rack::Lotus.any_instance.stubs(:render).returns("html")
  end

  describe "Authors Controller" do
    describe "GET /authors" do
      it "should query for all Lotus::Authors" do
        Lotus::Author.expects(:all)

        get '/authors'
      end

      it "should yield an array of all Lotus::Authors" do
        Lotus::Author.stubs(:all).returns([])

        # Ah. This is where I need a presenter pattern instead of instance
        # variable bullshits. I can't be extensible OR test state transfer
        # logic.

        get '/authors'
      end
    end

    describe "POST /authors/discover" do
      it "should attempt to discover the author in 'account' field" do
        acct = "acct:wilkie@rstat.us"
        Lotus.expects(:discover_author).with(acct).returns(nil)

        post '/authors/discover', "account" => acct
      end

      it "should not create an author when it is already known" do
        acct = "acct:wilkie@rstat.us"
        author = stub('Author')
        author.stubs(:uri).returns("foo")
        Lotus.stubs(:discover_author).with(acct).returns(author)
        Lotus::Author.stubs(:find).returns(author)

        Lotus::Author.expects(:create!).never

        post '/authors/discover', "account" => acct
      end

      it "should create an author when it is not known" do
        acct = "acct:wilkie@rstat.us"
        author = stub('Author')
        author.stubs(:uri).returns("foo")
        author.stubs(:to_hash).returns({})
        Lotus.stubs(:discover_author).with(acct).returns(author)
        Lotus::Author.stubs(:find).returns(nil)
        Lotus::Author.stubs(:sanitize_params)

        Lotus::Author.expects(:create!)

        post '/authors/discover', "account" => acct
      end

      it "should return 404 when the author is not discovered" do
        acct = "acct:noexists@rstat.us"
        Lotus.stubs(:discover_author).with(acct).returns(nil)

        post '/authors/discover', "account" => acct
        last_response.status.must_equal 404
      end

      it "should redirect when the author is discovered but exists" do
        acct = "acct:wilkie@rstat.us"
        author = stub('::Lotus::Author')
        author.stubs(:uri).returns("foo")
        author.stubs(:_id).returns("ID")
        Lotus.stubs(:discover_author).with(acct).returns(author)
        Lotus::Author.stubs(:find).returns(author)

        post '/authors/discover', "account" => acct
        last_response.status.must_equal 302
      end

      it "should redirect to the author when discovered but exists" do
        acct = "acct:wilkie@rstat.us"
        author = stub('::Lotus::Author')
        author.stubs(:uri).returns("foo")
        author.stubs(:_id).returns("ID")
        Lotus.stubs(:discover_author).with(acct).returns(author)
        Lotus::Author.stubs(:find).returns(author)

        post '/authors/discover', "account" => acct
        last_response.location.must_equal "http://example.org/authors/ID"
      end

      it "should redirect when the author is discovered and is created" do
        acct = "acct:wilkie@rstat.us"
        author = stub('::Lotus::Author')
        author.stubs(:uri).returns("foo")
        author.stubs(:_id).returns("ID")
        author.stubs(:to_hash)
        Lotus.stubs(:discover_author).with(acct).returns(author)
        Lotus::Author.stubs(:find).returns(nil)
        Lotus::Author.stubs(:sanitize_params)
        Lotus::Author.stubs(:create!).returns(author)

        post '/authors/discover', "account" => acct
        last_response.status.must_equal 302
      end

      it "should redirect to the author when discovered and is created" do
        acct = "acct:wilkie@rstat.us"
        author = stub('::Lotus::Author')
        author.stubs(:uri).returns("foo")
        author.stubs(:_id).returns("ID")
        author.stubs(:to_hash)
        Lotus.stubs(:discover_author).with(acct).returns(author)
        Lotus::Author.stubs(:find).returns(nil)
        Lotus::Author.stubs(:sanitize_params)
        Lotus::Author.stubs(:create!).returns(author)

        post '/authors/discover', "account" => acct
        last_response.location.must_equal "http://example.org/authors/ID"
      end
    end

    describe "GET /authors/:id" do
      it "should return 404 when the author is not found" do
        Lotus::Author.stubs(:find_by_id).returns(nil)

        get '/authors/1234abcd'
        last_response.status.must_equal 404
      end

      it "should return 200 when the author is found" do
        Lotus::Author.stubs(:find_by_id).returns(stub('author'))

        get '/authors/1234abcd'
        last_response.status.must_equal 200
      end
    end

    describe "GET /authors/:id/edit" do
      it "should return 404 when the author is not found" do
        Lotus::Author.stubs(:find_by_id).returns(nil)

        get '/authors/1234abcd/edit'
        last_response.status.must_equal 404
      end

      it "should return 200 when the author is found" do
        Lotus::Author.stubs(:find_by_id).returns(stub('author'))

        get '/authors/1234abcd/edit'
        last_response.status.must_equal 200
      end
    end

    describe "POST /authors/:id" do
      it "should return 404 when the author is not found" do
        Lotus::Author.stubs(:find_by_id).returns(nil)

        post '/authors/1234abcd'
        last_response.status.must_equal 404
      end

      it "should redirect when author is found and it is the logged in user" do
        author = stub('Author')
        author.stubs(:id).returns("ID")
        author.stubs(:update_attributes!)

        Lotus::Author.stubs(:find_by_id).returns(author)
        Lotus::Author.stubs(:sanitize_params).returns({:id => author.id})

        login_as("wilkie", author)

        post "/authors/#{author.id}"
        last_response.status.must_equal 302
      end

      it "should redirect to author when found and it is the logged in user" do
        author = stub('Author')
        author.stubs(:id).returns("ID")
        author.stubs(:update_attributes!)

        Lotus::Author.stubs(:find_by_id).returns(author)
        Lotus::Author.stubs(:sanitize_params).returns({"id" => author.id})

        login_as("wilkie", author)

        post "/authors/#{author.id}"
        last_response.location.must_equal "http://example.org/authors/#{author.id}"
      end

      it "should not allow injection of data to update_attributes" do
        author = stub('Author')
        author.stubs(:id).returns("ID")

        Lotus::Author.stubs(:find_by_id).returns(author)
        Lotus::Author.stubs(:sanitize_params).returns("sanitized")

        author.expects(:update_attributes!).with("sanitized")

        login_as("wilkie", author)

        post "/authors/#{author.id}", "foobar" => "moo"
      end

      it "should return 404 if the author, although exists, isn't logged on" do
        author = stub('Author')
        author.stubs(:id).returns("ID")
        author.stubs(:update_attributes!)

        Lotus::Author.stubs(:find_by_id).returns(author)
        Lotus::Author.stubs(:sanitize_params).returns({:id => author.id})

        post "/authors/#{author.id}"
        last_response.status.must_equal 404
      end

      it "should return 404 if another person then owner attempts to edit" do
        author = stub('Author')
        author.stubs(:id).returns("ID")
        author.stubs(:update_attributes!)

        Lotus::Author.stubs(:find_by_id).returns(author)
        Lotus::Author.stubs(:sanitize_params).returns({:id => author.id})

        login_as("intruder")

        post "/authors/#{author.id}"
        last_response.status.must_equal 404
      end
    end

    describe "GET /authors/:id/avatar/edit" do
      it "should return 404 when the author is not found" do
        Lotus::Author.stubs(:find_by_id).returns(nil)

        get '/authors/1234abcd/avatar/edit'
        last_response.status.must_equal 404
      end

      it "should return 200 when the author is found" do
        Lotus::Author.stubs(:find_by_id).returns(stub('author'))

        get '/authors/1234abcd/avatar/edit'
        last_response.status.must_equal 200
      end
    end

    describe "POST /authors/:id/avatar" do
      it "should return 404 when the author is not found" do
        Lotus::Author.stubs(:find_by_id).returns(nil)

        post '/authors/1234abcd/avatar'
        last_response.status.must_equal 404
      end

      it "should redirect when author is found and it is the logged in user" do
        author = stub('Author')
        author.stubs(:id).returns("ID")
        author.stubs(:update_avatar!)

        Lotus::Author.stubs(:find_by_id).returns(author)

        login_as("wilkie", author)

        post "/authors/#{author.id}/avatar"
        last_response.status.must_equal 302
      end

      it "should redirect to author when found and it is the logged in user" do
        author = stub('Author')
        author.stubs(:id).returns("ID")
        author.stubs(:update_avatar!)

        Lotus::Author.stubs(:find_by_id).returns(author)

        login_as("wilkie", author)

        post "/authors/#{author.id}/avatar"
        last_response.location.must_equal "http://example.org/authors/#{author.id}"
      end

      it "should update the avatar with the given url" do
        author = stub('Author')
        author.stubs(:id).returns("ID")

        Lotus::Author.stubs(:find_by_id).returns(author)

        author.expects(:update_avatar!).with("AVATAR_URL")

        login_as("wilkie", author)

        post "/authors/#{author.id}/avatar", "avatar_url" => "AVATAR_URL"
      end

      it "should return 404 if the author, although exists, isn't logged on" do
        author = stub('Author')
        author.stubs(:id).returns("ID")
        author.stubs(:update_avatar!)

        Lotus::Author.stubs(:find_by_id).returns(author)

        post "/authors/#{author.id}/avatar"
        last_response.status.must_equal 404
      end

      it "should return 404 if another person then owner attempts to edit" do
        author = stub('Author')
        author.stubs(:id).returns("ID")
        author.stubs(:update_avatar!)

        Lotus::Author.stubs(:find_by_id).returns(author)

        login_as("intruder")

        post "/authors/#{author.id}/avatar"
        last_response.status.must_equal 404
      end
    end
  end
end

