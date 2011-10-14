class RedisPusher
  @redis = Redis.new
  
  def self.push_data channel, data
    jsonized_data = JSON.generate(data)
    begin
      @redis.publish(channel,jsonized_data)
    rescue Errno::ECONNREFUSED
      #redis isn't running - clients won't be notified of changes
    end
  end
end