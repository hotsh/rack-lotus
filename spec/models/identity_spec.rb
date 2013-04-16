require_relative 'helper'
require_model 'identity'

describe Identity do
  describe "Schema" do
    it "should have a username" do
      Identity.keys.keys.must_include "username"
    end

    it "should have an ssl field" do
      Identity.keys.keys.must_include "ssl"
    end

    it "should have a domain" do
      Identity.keys.keys.must_include "domain"
    end

    it "should have a public_key" do
      Identity.keys.keys.must_include "public_key"
    end

    it "should have a salmon_endpoint" do
      Identity.keys.keys.must_include "salmon_endpoint"
    end

    it "should have a dialback_endpoint" do
      Identity.keys.keys.must_include "dialback_endpoint"
    end

    it "should have an activity_inbox_endpoint" do
      Identity.keys.keys.must_include "activity_inbox_endpoint"
    end

    it "should have an activity_outbox_endpoint" do
      Identity.keys.keys.must_include "activity_inbox_endpoint"
    end

    it "should have a profile_page" do
      Identity.keys.keys.must_include "profile_page"
    end

    it "should have an outbox_id" do
      Identity.keys.keys.must_include "outbox_id"
    end

    it "should have a created_at" do
      Identity.keys.keys.must_include "created_at"
    end

    it "should have a updated_at" do
      Identity.keys.keys.must_include "updated_at"
    end
  end

  describe "find_by_identifier" do
    it "should return nil when the identifier cannot be found" do
      Identity.create!(:username => "bogus",
                       :domain   => "rstat.us")

      Identity.find_by_identifier("wilkie@rstat.us").must_equal nil
    end

    it "should return the Identity when the identifier is found" do
      identity = Identity.create!(:username => "wilkie",
                                  :domain   => "rstat.us")

      Identity.find_by_identifier("wilkie@rstat.us").must_equal identity
    end

    it "should search without case sensitivity of the username" do
      identity = Identity.create!(:username => "WilkiE",
                                  :domain   => "rstat.us")

      Identity.find_by_identifier("wiLkIe@rstat.us").must_equal identity
    end

    it "should search without case sensitivity of the domain" do
      identity = Identity.create!(:username => "wilkie",
                                  :domain   => "rStat.uS")

      Identity.find_by_identifier("wilkie@rstAt.Us").must_equal identity
    end

    it "should ignore url scheme" do
      identity = Identity.create!(:username => "wilkie",
                                  :domain   => "rstat.us")

      Identity.find_by_identifier("acct:wilkie@rstat.us").must_equal identity
    end
  end

  describe "create!" do
    it "should take a Lotus::Identity" do
      identity = Lotus::Identity.new
      identity.stubs(:to_hash).returns({"username" => "wilkie"})

      Identity.create!(identity).username.must_equal "wilkie"
    end

    it "should allow a hash of values" do
      Identity.create!("username" => "wilkie").username.must_equal "wilkie"
    end

    it "should not store arbitrary fields" do
      Identity.expects(:new)
        .with(Not(has_entry(:foobar, "bar")))

      Identity.create!(:foobar => "bar")
    end
  end

  describe "sanitize_params" do
    it "should allow Identity keys" do
      hash = {}
      Identity.keys.keys.each do |k|
        next if ["_id"].include? k
        hash[k] = "foobar"
      end

      hash = Identity.sanitize_params(hash)

      Identity.keys.keys.each do |k|
        next if ["_id"].include? k
        hash[k].must_equal "foobar"
      end
    end

    it "should convert symbols to strings" do
      hash = {}
      Identity.keys.keys.each do |k|
        next if ["_id"].include? k
        hash[k.intern] = "foobar"
      end

      hash = Identity.sanitize_params(hash)

      Identity.keys.keys.each do |k|
        next if ["_id"].include? k
        hash[k].must_equal "foobar"
      end
    end

    it "should not allow _id" do
      hash = {"_id" => "bogus"}
      hash = Identity.sanitize_params(hash)
      hash.keys.wont_include "_id"
    end

    it "should not allow arbitrary keys" do
      hash = {:bogus => "foobar"}

      hash = Identity.sanitize_params(hash)

      hash.keys.wont_include :bogus
    end
  end

  describe "discover!" do
    it "should use Lotus to discover an identity given the account" do
      Lotus.expects(:discover_identity)

      Identity.discover!("wilkie@rstat.us")
    end

    it "should simply report the identity if already known" do
      identity = Identity.create(:username => "wilkie",
                                 :domain => "rstat.us")
      Lotus.expects(:discover_identity).never

      Identity.discover!("wilkie@rstat.us").must_equal identity
    end

    it "should create the Identity upon discovery" do
      identity = Lotus::Identity.new
      Lotus.stubs(:discover_identity).returns(identity)

      Identity.stubs(:create!).with(identity)

      Identity.discover!("wilkie@rstat.us")
    end

    it "should return the created Identity upon discovery" do
      identity = Lotus::Identity.new
      Lotus.stubs(:discover_identity).returns(identity)

      Identity.stubs(:create!).with(identity).returns("new identity")

      Identity.discover!("wilkie@rstat.us").must_equal "new identity"
    end
  end
end
