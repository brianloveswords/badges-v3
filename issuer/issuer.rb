
class Issuer < Sinatra::Base
  use Rack::MethodOverride
  # settings
  set :version, "0.1"
  set :secret, 'badgegiver'
  # version
  get '/' do; "Issuer #{settings.version}"; end

  # Providing identity
  get '/identity.json' do
    {:name => 'Test Issuer', :secret => encrypt(settings.secret)}.to_json
  end

  # register identity with the hub
  get '/register' do
    data = {:identity => 'http://issuer.rembr.it/identity.json', :phrase => settings.secret}
    Typhoeus::Request.post('http://hub.rembr.it/issuer/register', :params => data).body
  end
  
  # award a badge
  get '/award-badge/:badge' do
    data = {:badge => "http://issuer.rembr.it/badge/bjb/#{params['badge']}", :phrase => settings.secret}
    Typhoeus::Request.post('http://hub.rembr.it/issuer/store', :params => data).body
  end
  
  # hardcoded badges
  get '/badge/bjb/javascript' do
    badge = {
      :suborg => 'School of Webcraft',
      :title => 'JavaScript Ninja',
      :owner => 'brianloveswords@gmail.com',
      :description => 'Conferred for being totally wicked at JS',
      :image => '/images/p2pu_js.png',
      :expires => 120,
    }.to_json
  end
  get '/badge/bjb/audio' do
    badge = {
      :suborg => 'National Writing Project',
      :title => 'Audio Master',
      :owner => 'brianloveswords@gmail.com',
      :description => 'Might as well call this guy Timbaland',
      :image => '/images/nwp_audio.png',
    }.to_json
  end
  get '/badge/bjb/video' do
    badge = {
      :suborg => 'National Writing Project',
      :title => 'Professional Video Editor',
      :owner => 'brianloveswords@gmail.com',
      :description => 'Damn near the finest editor of videos this side of Hollywood.',
      :image => '/images/nwp_video.png',
    }.to_json
  end
  get '/badge/bjb/science' do
    badge = {
      :suborg => 'National Writing Project',
      :title => 'Lord of Science',
      :owner => 'brianloveswords@gmail.com',
      :description => 'Granted for mastering Science!!!!111',
      :image => '/images/nwp_science.png',
    }.to_json
  end
  
  protected
  def encrypt phrase
    Digest::SHA2.new(256).update(phrase).to_s
  end
end



