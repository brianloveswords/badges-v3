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
    @badgesets = get_user_badges(@user)
    haml :backpack
  end

  # log a user out
  get '/logout' do
    session['user'] = nil
    redirect '/'
  end
  
  post '/' do
    session['user'] = params['email']
    redirect '/'
  end

  post '/update-privacy' do
    email = session['user']
    
    # TODO: don't hardcode my own email address for one
    headers = {"From" => email, "Authentication" => "this_is_a_password"}
    uri = 'http://hub.rembr.it/user/update'
    response = Typhoeus::Request.get(uri, :headers => headers, :params => {:badges => params[:badges] })
    response.body
  end
  
  
  protected
  def get_user_badges email
    headers = {"From" => email, "Authentication" => "this_is_a_password"}
    badges = JSON.parse(Typhoeus::Request.get('http://hub.rembr.it/user/badges', :headers => headers).body)
  end
end

  
