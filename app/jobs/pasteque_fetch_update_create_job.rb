class PastequeFetchUpdateCreateJob < ActiveJob::Base
  queue_as :default
  include Rails.application.routes.url_helpers

  def perform
    #TODO
    begin
      Pasteque::PastequeIntegration.fetch_category.execute do |c|
        c.success do |list|
          list.map do |category|
            puts category.inspect.green
          end
        end
      end
    rescue StandardError => error
      Rails.logger.error $!
      Rails.logger.error $!.backtrace.join("\n")
      ExceptionNotifier.notify_exception($!, data: { message: error })
    end
  end
end
