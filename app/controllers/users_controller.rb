class UsersController < ApplicationController

  def index
    @user = User.new
    @users = User.all
    @current_id = session[:current_user_id]
    @current_name = User.find(@current_id).name if @current_id
  end

  def create
    @user = User.new(filted_params)
    @user.password = filted_params[:password]
    if @user.save!
      redirect_to root_path
    else
      render :index
    end
  end

 
private

  def filted_params
    params.require(:user).permit(:name, :password)
  end

end
