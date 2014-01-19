# ~*~ encoding: utf-8 ~*~

require 'omniauth-openid'
require 'openid'
require 'openid/store/filesystem'
require 'gapps_openid'

OmniAuth.config.on_failure = Proc.new{|env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}

module Precious
  module AuthRoute

    def self.registered(base)
        #provider :open_id,
        #    :name => 'gapps',
        #    :identifier => "https://www.google.com/accounts/o8/site-xrds?hd=altab.jp",
        #    :store => OpenID::Store::Filesystem.new('/tmp/sessions')

      base.use Rack::Session::Cookie, :secret => 'supers3cr3t'
      base.use OmniAuth::Builder do
        provider :open_id,
          :name => 'gapps',
          :store => OpenID::Store::Filesystem.new('/tmp/sessions'),
          :setup => true
      end

      base.get '/auth/:provider/setup' do
        request.env['omniauth.strategy'].options[:identifier] = \
          "https://www.google.com/accounts/o8/site-xrds?hd=#{App.auth_domain}"
        halt 404
      end

      base.post '/auth/:provider/callback' do
        auth_details = request.env['omniauth.auth']
        session[:name]  = auth_details.info['name']
        session[:email] = auth_details.info['email']
        redirect "/auth/#{params[:provider]}/welcome"
      end

      base.get '/auth/:provider/welcome' do
        if base.is_authed?(session)
          redirect '/'
        else
          redirect "/auth/failure"
        end
      end

      base.get '/auth/signout' do
        session.clear
        'signout completed.'
      end

      base.get '/auth/failure' do
        params['message']
        # do whatever you want here.
      end

      def auth_request?(request)
        method = request.request_method.downcase
        path   = request.path_info

        case method
        when 'post'
          ('/auth/gapps/callback' == path)
        when 'get'
          %w[/auth/gapps /auth/gapps/setup /auth/signout /auth/failure].include?(path)
        else
          false
        end
      end

      def is_authed?(session)
        name = session[:name]
        !(name.nil? or name.empty?)
      end
    end

  end
end

