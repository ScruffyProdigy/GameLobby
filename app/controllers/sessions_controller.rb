class SessionsController < ApplicationController
  def new
  end
  
  def create
    user = User.authenticate!(params)
    if user
      sign_in user
      redirect_to root_url, :notice=>"logged in!"
    else
      flash.now.alert = "Invalid email or password"
      render "new"
    end
  end
  
  def destroy
    sign_out
    redirect_to root_url, :notice => "logged out!"
  end

end
