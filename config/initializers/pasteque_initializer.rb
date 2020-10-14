Pasteque::PastequeIntegration.on_check_success do
  PastequeFetchUpdateCreateJob.perform_later
end

Pasteque::PastequeIntegration.run every: :day do
  PastequeFetchUpdateCreateJob.perform_now
end
