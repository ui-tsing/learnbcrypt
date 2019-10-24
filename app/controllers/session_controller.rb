class SessionController < ApplicationController
  def login
    @user = User.find_by(name: params[:name])
    if @user.password == params[:password]
      session[:current_user_id] = @user.id
    else
      render :index
    end
    
    redirect_to root_path
  end

  def destroy
    session.destroy
    redirect_to root_path
  end
end
