require 'exceptions'

class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :load_redis
  helper_method :current_user
  helper_method :logged_in?
  
  include Exceptions
  
  private
  
  def load_redis
    @redis = Redis.new
  end
  
  def push_data channel, data
    jsonized_data = JSON.generate(data)
    logger.info("pushing #{jsonized_data} to #{channel}")
    @redis.publish(channel, jsonized_data)
  end
  
  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
  
  def logged_in?
    not current_user.nil?
  end
  
end
