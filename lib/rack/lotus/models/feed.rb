# This represents a collection of activities.
class Feed
  include MongoMapper::Document

  key :id
  key :url
  key :categories,   :default => []
  key :rights
  key :title
  key :title_type
  key :subtitle
  key :subtitle_type
  key :icon
  key :logo
  key :generator
  key :contributors, Array, :default => []
  key :authors,      Array, :default => []
  key :entries_ids,  Array
  many :entries,      :class_name => 'Activity', :in => :entries_ids
  key :hubs,         Array, :default => []
  key :salmon_url

  # Subscription status.
  # Since subscriptions are done by the server, we only need to share one
  # secret/token pair for all users that follow this feed on the server.
  key :subscription_secret
  key :verification_token

  # TODO: Normalize the first 100 or so activities. I dunno.
  key :normalized

  timestamps!

  # Create a new Feed from a Hash of values or a Lotus::Feed.
  def self.create!(arg, *args)
    if arg.is_a? Lotus::Feed
      arg = arg.to_hash

      arg.delete :entries
      arg.delete :authors
    end

    super arg, *args
  end

  # Adds activity to the feed.
  def post!(activity)
    activity.feed = self
    activity.save

    self.entries << activity
    self.save
  end

  # Reposts an activity from another feed.
  def repost!(activity)
    self.entries << activity
    self.save
  end

  # Merges the information in the given feed with this one.
  def merge!(feed)
    # Merge metadata
    meta_data = feed.to_hash
    meta_data.delete :entries
    meta_data.delete :authors
    meta_data.delete :contributors
    self.update_attributes!(meta_data)

    # Merge new/updated authors
    feed.authors.each do |author|
    end

    # Merge new/updated activities
    feed.entries.each do |activity|
    end
  end

  # Pings the hub or owner of this feed
  def ping
    self.hubs.each do |h|
      puts "PING #{h}"
    end
  end
end
