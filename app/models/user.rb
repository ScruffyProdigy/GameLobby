class User < ActiveRecord::Base
  
  attr_accessible :email, :password, :password_confirmation
  attr_accessor :password
  before_save :encrypt_password
  
  validates :password, :presence=>true, :on => :create  
  validates :password, :confirmation=>true
  validates :email, :presence=>true, :uniqueness=>true  
    
  has_many :players #the player is just the user's incarnation within the clash
  has_many :clashes, :through=>:players
  
  def encrypt_password
    if password.present?
      self.password_salt = BCrypt::Engine.generate_salt  
      self.password_hash = BCrypt::Engine.hash_secret(password, password_salt)
    end
  end
  
  def self.authenticate_with_email_and_password email,password
    user = find_by_email email
    if user and user.password_hash == BCrypt::Engine.hash_secret(password, user.password_salt)
      return user
    else
      return nil
    end
  end
  
  def self.authenticate! params
    if params[:email] and params[:password]
      return self.authenticate_with_email_and_password( params[:email], params[:password])
    end
    
    return nil
  end
  
  def url
    #GIANT HACK!
    return "http://localhost/users/#{self.id}/"
  end
  
  def self.get_id_from_url url
    match = /http:\/\/localhost\/users\/(\d+)\//.match(url)
    match ? match[1] : nil
  end
end