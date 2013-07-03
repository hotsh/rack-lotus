module Rack
  class Lotus
    # Get a listing of the people on this server.
    get '/people' do
      people = ::Lotus::Person.all
      render :haml, :"people/index", :locals => {:people => people}
    end

    # Get the public profile for this person.
    get '/people/:id' do
      person = ::Lotus::Person.find_by_id(params[:id])
      status 404 and return if person.nil?

      timeline = person.activities.feed.ordered
      render :haml, :"people/show", :locals => {:person => person,
                                                :timeline => timeline}
    end

    # Get the public feed for our timeline.
    get '/people/:id/timeline' do
      person = ::Lotus::Person.find_by_id(params[:id])
      status 404 and return if person.nil?

      timeline = person.timeline.feed.ordered

      if pjax?
        render :haml, :"people/_timeline", :locals => {:person => person,
                                                       :timeline => timeline},
                                           :layout => false
      else
        render :haml, :"people/timeline", :locals => {:person => person,
                                                      :timeline => timeline}
      end
    end

    # Get the public feed for our timeline.
    get '/people/:id/activities' do
      person = ::Lotus::Person.find_by_id(params[:id])
      status 404 and return if person.nil?

      activities = person.activities.feed.ordered
      render :haml, :"people/activities", :locals => {:person => person,
                                                      :activities => activities}
    end

    # Get the public feed for our mentions.
    get '/people/:id/mentions' do
      person = ::Lotus::Person.find_by_id(params[:id])
      status 404 and return if person.nil?

      mentions = person.mentions.feed.ordered

      if pjax?
        render :haml, :"people/_mentions", :locals => {:person => person,
                                                       :mentions => mentions},
                                           :layout => false
      else
        render :haml, :"people/mentions", :locals => {:person => person,
                                                      :mentions => mentions}
      end
    end

    # Get the public feed for our replies.
    get '/people/:id/replies' do
      person = ::Lotus::Person.find_by_id(params[:id])
      status 404 and return if person.nil?

      replies = person.replies.feed.ordered
      render :haml, :"people/replies", :locals => {:person => person,
                                                   :replies => replies}
    end

    # Get the public feed for somebody's favorites.
    get '/people/:id/favorites' do
      person = ::Lotus::Person.find_by_id(params[:id])
      status 404 and return if person.nil?

      favorites = person.favorites.feed.ordered

      if pjax?
        render :haml, :"people/_favorites", :locals => {:person => person,
                                                        :favorites => favorites},
                                            :layout => false
      else
        render :haml, :"people/favorites", :locals => {:person => person,
                                                       :favorites => favorites}
      end
    end

    # Get the public feed for somebody's feed of shared posts.
    get '/people/:id/shared' do
      person = ::Lotus::Person.find_by_id(params[:id])
      status 404 and return if person.nil?

      shared = person.shared.feed.ordered
      render :haml, :"people/shared", :locals => {:person => person,
                                                  :shared => shared}

      if pjax?
        render :haml, :"people/_shared", :locals => {:person => person,
                                                     :shared => shared},
                                         :layout => false
      else
        render :haml, :"people/shared", :locals => {:person => person,
                                                    :shared => shared}
      end
    end

    # Retrieve list of people we follow
    get '/people/:id/following' do
      person = ::Lotus::Person.find_by_id(params["id"])
      status 404 and return unless person

      following = person.following

      render :haml, :"people/following", :locals => {:person => person,
                                                     :following => following}
    end

    # Retrieve a list of people who are following us.
    get '/people/:id/followers' do
      person = ::Lotus::Person.find_by_id(params["id"])
      status 404 and return unless person

      followers = person.followers

      render :haml, :"people/followers", :locals => {:person => person,
                                                     :followers => followers}
    end

    # Follow a person
    post '/people/:id/following' do
      status 404 and return unless current_person &&
                                   current_person.id.to_s == params["id"]

      if params["author_id"]
        author = ::Lotus::Author.find_by_id(params["author_id"])
      elsif params["discover"]
        author = ::Lotus::Author.discover!(params["discover"])
      end

      status 404 and return unless author

      current_person.follow! author
      redirect '/'
    end

    # Unfollow a person
    delete '/people/:id/following/:followed_id' do
      status 404 and return unless current_person &&
                                   current_person.id.to_s == params["id"]

      current_person.unfollow! params["followed_id"]
      redirect '/'
    end

    # Favorite an activity
    post '/people/:id/favorites' do
      status 404 and return unless current_person &&
                                   current_person.id.to_s == params["id"]

      activity = ::Lotus::Activity.find_by_id(params["activity_id"])

      status 404 and return unless activity

      current_person.favorite! activity
      redirect '/'
    end

    # Share an activity
    post '/people/:id/shared' do
      status 404 and return unless current_person &&
                                   current_person.id.to_s == params["id"]

      activity = ::Lotus::Activity.find_by_id(params["activity_id"])

      status 404 and return unless activity

      current_person.share! activity
      redirect '/'
    end

    # External delivery to our own stream.
    post '/people/:id/timeline' do
      person = ::Lotus::Person.find_by_id(params[:id])
      status 404 and return if person.nil?
    end

    # External delivery of followed activity streams.
    post '/people/:id/inbox' do
      person = ::Lotus::Person.find_by_id(params[:id])
      status 404 and return if person.nil?
    end

    # External delivery of direct messages.
    post '/people/:id/direct' do
      person = ::Lotus::Person.find_by_id(params[:id])
      status 404 and return if person.nil?
    end

    # Creates a new activity.
    post '/people/:id/activities' do
      status 404 and return unless current_person &&
                                   current_person.id.to_s == params["id"]

      object =
        case params["type"]
        when "note", "status"
          ::Lotus::Note.new(:title => "New Status",
                            :author_id => current_person.author.id,
                            :text  => params["content"])
        when "article"
          ::Lotus::Article.new(:title    => params["title"],
                               :author_id => current_person.author.id,
                               :content  => params["content"],
                               :markdown => params["markdown"])
        when "image"
          ::Lotus::Image.from_blob!(current_person.author,
                                    params["file"][:tempfile].read)
        else
          nil
        end

      current_person.post!(:type   => params["type"],
                           :verb   => :post,
                           :actor  => current_person.author,
                           :object => object)

      redirect '/'
    end

    # Handle a salmon payload
    post '/people/:id/salmon' do
      person = ::Lotus::Person.find_by_id(params[:id])
      status 404 and return if person.nil?

      # Form the notification
      notification = ::Lotus::Notification.from_xml(request.body.read)

      # If it already exists, this will update
      activity = ::Lotus::Activity.find_from_notification(notification)

      if activity
        activity = activity.update_from_notification!(notification)

        # Failure to verify (Forbidden)
        status 403 and return if activity.nil?
        success = 200
      else
        activity = ::Lotus::Activity.create_from_notification!(notification)

        # Failure to verify (Bad Request)
        status 400 and return if activity.nil?
        success = 202
      end

      case activity.verb
      when :follow
        person.followed_by! nil
      when :unfollow
        person.unfollowed_by! identity.author
      when :post
        # TODO: determine who is mentioned, replied and deliver if this is
        #       "person"
      end

      headers["Location"] = activity.url
      status success
    end
  end
end
