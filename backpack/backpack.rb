class Backpack < Sinatra::Base
  use Rack::MethodOverride
  set :version, "0.1"
  enable :sessions
  
  # either present login form or show badges
  get '/' do
    @version = settings.version
    unless session['user']
      return haml :index
    end
    @user = session['user']
    @encoded_user = Base64.encode64(@user).chomp.gsub('==', '')
    @badgesets = get_user_badges(@user)
    haml :backpack
  end

  # log a user out
  get '/logout' do
    session['user'] = nil
    redirect '/'
  end
  
  # log a user in
  post '/' do
    session['user'] = params['email']
    redirect '/'
  end

  post '/update-privacy' do
    email = session['user']
    headers = {"From" => email, "Authentication" => "this_is_a_password"}
    uri = 'http://hub.rembr.it/user/badges'
    
    # TODO: figure out why it destroys inner arrays if I don't pass as json
    response = Typhoeus::Request.put(uri, :headers => headers, :params => {:badges => params[:badges].to_json })
    response.body
  end
  
  
  protected
  def get_user_badges email
    # TODO: make sure the user exists AND/OR
    # TODO: fail gracefully when the user doesn't exist
    headers = {"From" => email, "Authentication" => "this_is_a_password"}
    badges = JSON.parse(Typhoeus::Request.get('http://hub.rembr.it/user/badges', :headers => headers).body)
  end
end

  
