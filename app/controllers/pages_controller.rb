class PagesController < ApplicationController
  def home
    redirect_to child_profiles_path if user_signed_in?
  end
end
