class RedisPusher
  @redis = Redis.new
  
  def self.push_data channel, data
    jsonized_data = JSON.generate(data)
    @redis.publish(channel,jsonized_data)
  end
end