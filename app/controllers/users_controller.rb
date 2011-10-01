class UsersController < ApplicationController
  before_filter :find_user, :only=>[:show,:edit,:update,:destroy]
  
  respond_to :html, :xml, :json
  
  def index
    respond_with(@users = User.all)
  end
  
  def show
    respond_with @user
  end
  
  def new
    @user = User.new
    respond_with @user
  end
  
  def create
    @user = User.new(params[:user])
    if @user.save
      session[:user_id] = @user.id
      redirect_to root_url, :notice => "Signed Up!"
    else
      render "new"
    end
  end
  
  def edit
    respond_with @user
  end
  
  def update
    if @user.update_attributes(params[:user])
      respond_with @user
    else
      render "edit"
    end
  end
  
  def destroy
    @user.destroy
    respond_with @user, :location=>users_path
  end
  
  protected
  def find_user
    @user = User.find(params[:id])
    if @user.nil?
      redirect_to users_path
    end
  end
end