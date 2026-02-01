class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # Disabled to support older browsers used by district leaders
  # allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Use auth layout for Devise controllers, application layout for others
  layout :layout_by_resource

  private

  def layout_by_resource
    if devise_controller?
      'auth'
    else
      'application'
    end
  end
end
