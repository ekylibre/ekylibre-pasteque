module EkylibrePasteque
  class ApplicationController < Backend::BaseController
    protect_from_forgery with: :exception

    layout 'assets_injection_layout'
  end
end
