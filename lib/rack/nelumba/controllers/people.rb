module Rack
  class Nelumba
    # Get a listing of the people on this server.
    get '/people' do
      people = ::Nelumba::Person.all
      render :haml, :"people/index", :locals => {
        :people => people
      }
    end

    # Get a field to discover a new Nelumba::Person.
    get '/people/discover' do
      haml :"people/discover"
    end

    # Discover a new Nelumba::Person.
    post '/people/discover' do
      author = ::Nelumba::Person.discover!(params["account"])

      if author
        redirect "/people/#{author.id}"
      else
        status 404
      end
    end

    # Edit a known Nelumba::Person
    get '/people/:id/edit' do
      person = ::Nelumba::Person.find_by_id(params[:id])
      if person.nil?
        status 404
      else
        render :haml, :"people/edit", :locals => {
          :person => person
        }
      end
    end

    # Update a known Nelumba::Person
    post '/people/:id' do
      params = params() # Can't pass it unless it is a hash

      person = ::Nelumba::Person.find_by_id(params[:id])
      if person.nil? || current_person.nil? || (person.id != current_person.id)
        # Do not allow creation
        status 404
      else
        params = ::Nelumba::Person.sanitize_params(params)
        person.update_attributes!(params)

        redirect "/people/#{person.id}"
      end
    end

    # Get the public profile for this person.
    get '/people/:id' do
      person = ::Nelumba::Person.find_by_id(params[:id])
      status 404 and return if person.nil?

      # Set up HTTP link for LRDD
      if person.authorization
        response.headers["Link"] = "</api/lrdd/#{person.authorization.username}>; rel=\"lrdd\"; type=\"application/xrd+xml\""
      end

      # Set up other links
      links = []
      links << {:rel => "alternate",
                :type => "application/atom+xml",
                :href => "/people/#{person.id}/activities"}
      links << {:rel => "alternate",
                :type => "application/json",
                :href => "/people/#{person.id}/activities"}

      timeline = person.activities.ordered
      render :haml, :"people/show", :locals => {
        :person   => person,
        :timeline => timeline,
        :links    => links
      }
    end

    # Edit the author avatar
    get '/people/:id/avatar/edit' do
      person = ::Nelumba::Person.find_by_id(params[:id])
      if person.nil?
        status 404
      else
        render :haml, :"people/edit_avatar", :locals => {
          :person   => person
        }
      end
    end

    # Update an avatar for a known Nelumba::Person
    post '/people/:id/avatar' do
      person = ::Nelumba::Person.find_by_id(params[:id])
      if person.nil? || current_person.nil? || (person.id != current_person.id)
        # Do not allow creation
        status 404
      else
        url = params["avatar_url"]
        person.update_avatar!(url)

        redirect "/people/#{person.id}"
      end
    end

    # TODO: Get avatar for person

    # Get the public feed for our timeline.
    get '/people/:id/timeline' do
      person = ::Nelumba::Person.find_by_id(params[:id])
      status 404 and return if person.nil?

      timeline = person.timeline.ordered

      if pjax?
        render :haml, :"people/_timeline", :locals => {
          :person => person,
          :timeline => timeline
        }, :layout => false
      elsif request.preferred_type('text/html')
        render :haml, :"people/timeline", :locals => {
          :person => person,
          :timeline => timeline
        }
      elsif request.preferred_type('application/json')
        content_type 'application/json'
        person.timeline.to_json
      elsif request.preferred_type('application/atom+xml') ||
            request.preferred_type('application/xml')
        content_type 'application/atom+xml'
        person.timeline.to_atom
      else
        status 406
      end
    end

    # Get the public feed for our timeline.
    get '/people/:id/activities' do
      person = ::Nelumba::Person.find_by_id(params[:id])
      status 404 and return if person.nil?

      activities = person.activities.ordered

      if pjax?
        render :haml, :"people/_activities", :locals => {
          :person => person,
          :activities => activities
        }, :layout => false
      elsif request.preferred_type('text/html')
        render :haml, :"people/activities", :locals => {
          :person => person,
          :activities => activities
        }
      elsif request.preferred_type('application/json')
        content_type 'application/json'
        activities.to_json
      elsif request.preferred_type('application/atom+xml') ||
            request.preferred_type('application/xml')
        content_type 'application/atom+xml'
        person.activities.to_atom
      else
        status 406
      end
    end

    # Get the public feed for our mentions.
    get '/people/:id/mentions' do
      person = ::Nelumba::Person.find_by_id(params[:id])
      status 404 and return if person.nil?

      mentions = person.mentions.ordered

      if pjax?
        render :haml, :"people/_mentions", :locals => {
          :person => person,
          :mentions => mentions
        }, :layout => false
      elsif request.preferred_type('text/html')
        render :haml, :"people/mentions", :locals => {
          :person => person,
          :mentions => mentions
        }
      elsif request.preferred_type('application/json')
        content_type 'application/json'
        mentions.to_json
      elsif request.preferred_type('application/atom+xml') ||
            request.preferred_type('application/xml')
        content_type 'application/atom+xml'
        mentions.to_xml
      else
        status 406
      end
    end

    # Get the public feed for our replies.
    get '/people/:id/replies' do
      person = ::Nelumba::Person.find_by_id(params[:id])
      status 404 and return if person.nil?

      replies = person.replies.ordered
      render :haml, :"people/replies", :locals => {:person => person,
                                                   :replies => replies}
    end

    # Get the public feed for somebody's favorites.
    get '/people/:id/favorites' do
      person = ::Nelumba::Person.find_by_id(params[:id])
      status 404 and return if person.nil?

      favorites = person.favorites.ordered

      if pjax?
        render :haml, :"people/_favorites", :locals => {:person => person,
                                                        :favorites => favorites},
                                            :layout => false
      elsif request.preferred_type('text/html')
        render :haml, :"people/favorites", :locals => {:person => person,
                                                       :favorites => favorites}
      elsif request.preferred_type('application/json')
        content_type 'application/json'
        favorites.to_json
      elsif request.preferred_type('application/atom+xml') ||
            request.preferred_type('application/xml')
        content_type 'application/atom+xml'
        favorites.to_xml
      else
        status 406
      end
    end

    # Get the public feed for somebody's feed of shared posts.
    get '/people/:id/shared' do
      person = ::Nelumba::Person.find_by_id(params[:id])
      status 404 and return if person.nil?

      shared = person.shared.ordered
      render :haml, :"people/shared", :locals => {
        :person => person,
        :shared => shared
      }

      if pjax?
        render :haml, :"people/_shared", :locals => {
          :person => person,
          :shared => shared
        }, :layout => false
      elsif request.preferred_type('text/html')
        render :haml, :"people/shared", :locals => {
          :person => person,
          :shared => shared
        }
      elsif request.preferred_type('application/json')
        content_type 'application/json'
        shared.to_json
      elsif request.preferred_type('application/atom+xml') ||
            request.preferred_type('application/xml')
        content_type 'application/atom+xml'
        shared.to_xml
      else
        status 406
      end
    end

    # Retrieve list of people we follow
    get '/people/:id/following' do
      person = ::Nelumba::Person.find_by_id(params["id"])
      status 404 and return unless person

      following = person.following

      if pjax?
        render :haml, :"people/_following", :locals => {
          :person    => person,
          :following => following
        }, :layout => false
      else
        # TODO: html/json/etc
        render :haml, :"people/following", :locals => {
          :person    => person,
          :following => following
        }
      end
    end

    # Retrieve a list of people who are following us.
    get '/people/:id/followers' do
      person = ::Nelumba::Person.find_by_id(params["id"])
      status 404 and return unless person

      followers = person.followers

      if pjax?
        render :haml, :"people/_followers", :locals => {
          :person    => person,
          :followers => followers
        }, :layout => false
      else
        # TODO: html/json/etc
        render :haml, :"people/followers", :locals => {
          :person => person,
          :followers => followers
        }
      end
    end

    # Follow a person
    post '/people/:id/following' do
      status 404 and return unless current_person &&
                                   current_person.id.to_s == params["id"]

      if params["author_id"]
        author = ::Nelumba::Person.find_by_id(params["author_id"])
      elsif params["discover"]
        author = ::Nelumba::Person.discover!(params["discover"])
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

      activity = ::Nelumba::Activity.find_by_id(params["activity_id"])

      status 404 and return unless activity

      current_person.favorite! activity
      redirect '/'
    end

    # Share an activity
    post '/people/:id/shared' do
      status 404 and return unless current_person &&
                                   current_person.id.to_s == params["id"]

      activity = ::Nelumba::Activity.find_by_id(params["activity_id"])

      status 404 and return unless activity

      current_person.share! activity
      redirect '/'
    end

    # External delivery to our own stream.
    post '/people/:id/timeline' do
      person = ::Nelumba::Person.find_by_id(params[:id])
      status 404 and return if person.nil?
    end

    # External delivery of followed activity streams.
    post '/people/:id/inbox' do
      person = ::Nelumba::Person.find_by_id(params[:id])
      status 404 and return if person.nil?
    end

    # External delivery of direct messages.
    post '/people/:id/direct' do
      person = ::Nelumba::Person.find_by_id(params[:id])
      status 404 and return if person.nil?
    end

    # Creates a new activity.
    post '/people/:id/activities' do
      status 404 and return unless current_person &&
                                   current_person.id.to_s == params["id"]

      object =
        case params["type"]
        when "note", "status"
          ::Nelumba::Note.new(:title     => "New Status",
                              :author_id => current_person.id,
                              :text      => params["content"])
        when "article"
          ::Nelumba::Article.new(:title     => params["title"],
                                 :author_id => current_person.id,
                                 :content   => params["content"],
                                 :markdown  => params["markdown"])
        when "image"
          ::Nelumba::Image.from_blob!(current_person,
                                      params["file"][:tempfile].read,
                                      :text         => params["content"],
                                      :title        => params["title"],
                                      :sizes        => [[650,160]],
                                      :content_type => params["file"][:type])
        else
          nil
        end

      current_person.post!(:type   => params["type"],
                           :verb   => :post,
                           :actor  => current_person,
                           :object => object)

      redirect '/'
    end

    # Handle a salmon payload
    post '/people/:id/salmon' do
      person = ::Nelumba::Person.find_by_id(params[:id])
      status 404 and return if person.nil?

      # Form the notification
      notification = ::Nelumba::Notification.from_xml(request.body.read)

      # If it already exists, this will update
      activity = ::Nelumba::Activity.find_from_notification(notification)

      if activity
        activity = activity.update_from_notification!(notification)

        # Failure to verify (Forbidden)
        status 403 and return if activity.nil?
        success = 200
      else
        activity = ::Nelumba::Activity.create_from_notification!(notification)

        # Failure to verify (Bad Request)
        status 400 and return if activity.nil?
        success = 202
      end

      case activity.verb
      when :follow
        person.followed_by! nil
      when :unfollow
        person.unfollowed_by! identity.person
      when :post
        # TODO: determine who is mentioned, replied and deliver if this is
        #       "person"
      end

      headers["Location"] = activity.url
      status success
    end
  end
end
