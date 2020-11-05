class PastequeFetchUpdateCreateJob < ActiveJob::Base
  queue_as :default
  include Rails.application.routes.url_helpers

  VENDOR = 'pasteque'
  DEFAULT_CATEGORY = :processed_product
  DEFAULT_VARIANT = :grape

  def perform
    #TODO
    begin
      # get category and create/update it
      Pasteque::PastequeIntegration.fetch_category.execute do |c|
        c.success do |list|
          list.each do |category|
            puts category.inspect.green
            create_or_update_category(category)
            # get product for this category and create/update it
            Pasteque::PastequeIntegration.fetch_product_by_category(category[:id]).execute do |c|
              c.success do |product_list|
                product_list.each do |product|
                  puts product.inspect.yellow
                  create_or_update_variant(product, category[:id])
                end
              end
            end
          end
        end
      end

      # get cash register (aka cashes)
      Pasteque::PastequeIntegration.fetch_cash_registers.execute do |c|
        c.success do |cash_registers|
          cash_registers.each do |cash_register|
            puts cash_register.inspect.red
            #create_or_update_cash(cash_register[:id])
          end
        end
      end

      # get payment mode (aka incoming_payment mode) for all cashes
      Pasteque::PastequeIntegration.fetch_payment_modes.execute do |c|
        c.success do |payment_modes|
          payment_modes.each do |payment_mode|
            puts payment_mode.inspect.yellow
            #create_or_update_incoming_payment_mode(payment_mode[:id])
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

  def create_or_update_category(vendor_category)
    pnc = ProductNatureCategory.where("provider ->> 'vendor' = ? AND (provider ->> 'id')::int = ?", VENDOR, vendor_category[:id]).first
    if pnc
      pnc.name = vendor_category[:reference]
      pnc.description = vendor_category[:label]
      pnc.save!
    else
      pnc = ProductNatureCategory.import_from_lexicon(DEFAULT_CATEGORY, true)
      pnc.name = vendor_category[:reference]
      pnc.description = vendor_category[:label]
      pnc.active = true
      pnc.provider = {vendor: VENDOR, id: vendor_category[:id]}
      pnc.save!
    end
  end

  def create_or_update_variant(product, vendor_category_id)
    pnc = ProductNatureCategory.where("provider ->> 'vendor' = ? AND (provider ->> 'id')::int = ?", VENDOR, vendor_category_id).first
    pnv = ProductNatureVariant.where("provider ->> 'vendor' = ? AND (provider ->> 'id')::int = ?", VENDOR, product[:id]).first
    if pnc && pnv
      pnv.name = product[:label]
      pnv.work_number = product[:reference]
      pnv.active = product[:visible]
      pnv.gtin = product[:barcode] if !product[:barcode].blank?
      pnv.category_id = pnc.id
      pnv.save!
    elsif pnc
      pnv = ProductNatureVariant.import_from_lexicon(DEFAULT_VARIANT, true)
      pnv.name = product[:label]
      pnv.work_number = product[:reference]
      pnv.active = product[:visible]
      pnv.gtin = product[:barcode] if !product[:barcode].blank?
      pnv.provider = {vendor: VENDOR, id: product[:id]}
      pnv.category_id = pnc.id
      pnv.save!
    end
    # create or update price for variant
  end

  def create_or_update_incoming_payment_mode(payment_mode_id)
    #TODO
  end

  def create_or_update_cash(cash_register_id)
    # TODO
  end
end
