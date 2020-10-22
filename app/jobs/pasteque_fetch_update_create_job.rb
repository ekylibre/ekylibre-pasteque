class PastequeFetchUpdateCreateJob < ActiveJob::Base
  queue_as :default
  include Rails.application.routes.url_helpers

  VENDOR = 'pasteque'

  def perform
    #TODO
    begin
      # get category and create/update it
      Pasteque::PastequeIntegration.fetch_category.execute do |c|
        c.success do |list|
          list.each do |category|
            puts category.inspect.green
            update_or_create_category(category)
            # get product for this category and create/update it
            Pasteque::PastequeIntegration.fetch_product_by_category.execute(category[:id]) do |c|
              c.success do |product_list|
                product_list.each do |product|
                  puts product.inspect.yellow
                  update_or_create_variant(product, category[:id])
                end
              end
            end
          end
        end
      end
    rescue StandardError => error
      Rails.logger.error $!
      Rails.logger.error $!.backtrace.join("\n")
      ExceptionNotifier.notify_exception($!, data: { message: error })
    end
  end

  private

  def update_or_create_category(vendor_category)
    pnc = ProductNatureCategory.where("provider ->> 'vendor' = ? AND (provider ->> 'id')::int = ?", VENDOR, vendor_category[:id]).first
    if pnc
      pnc.name = vendor_category[:reference]
      pnc.description = vendor_category[:label]
      pnc.save!
    else
      pnc = ProductNatureCategory.import_from_lexicon(:processed_product, true)
      pnc.name = vendor_category[:reference]
      pnc.description = vendor_category[:label]
      pnc.active = true
      pnc.provider = {vendor: VENDOR, id: vendor_category[:id]}
      pnc.save!
    end
  end

  def update_or_create_variant(product, vendor_category_id)
    pnc = ProductNatureCategory.where("provider ->> 'vendor' = ? AND (provider ->> 'id')::int = ?", VENDOR, vendor_category_id).first
    pnv = ProductNatureVariant.where("provider ->> 'vendor' = ? AND (provider ->> 'id')::int = ?", VENDOR, product[:id]).first
    if pnv
      pnv.name = product[:reference]
      pnv.description = product[:label]
      pnv.active = product[:visible]
      pnv.category_id = pnc.id
      pnv.save!
    else
      pnv = ProductNatureVariant.import_from_lexicon(:grape, true)
      pnv.name = product[:reference]
      pnv.description = product[:label]
      pnv.active = product[:visible]
      pnv.provider = {vendor: VENDOR, id: product[:id]}
      pnv.category_id = pnc.id
      pnv.save!
    end
    # create or update price for variant
  end

end
