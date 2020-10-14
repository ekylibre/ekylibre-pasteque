class PastequeFetchUpdateCreateJob < ActiveJob::Base
  queue_as :default
  include Rails.application.routes.url_helpers

  def perform
    #TODO
  end
end
