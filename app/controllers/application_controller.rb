class ApplicationController < ActionController::Base
  def index
    redirect_to operations_path
  end
end
