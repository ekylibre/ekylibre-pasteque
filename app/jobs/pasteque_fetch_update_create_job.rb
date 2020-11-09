class PastequeFetchUpdateCreateJob < ActiveJob::Base
  queue_as :default
  include Rails.application.routes.url_helpers

  VENDOR = 'pasteque'
  DEFAULT_CATEGORY = :processed_product
  DEFAULT_VARIANT = :grape

  attr_accessor :token

  # global notes
  # we don't manage country and currency for the moment
  # all is € and fr for taxes

  def perform
    # get token because it's refresh on each call in headers
    Pasteque::PastequeIntegration.get_token.execute do |c|
      c.success do |r|
        self.token = r
      end
    end

    puts token.inspect.red

    begin
      # get category and create/update it
      Pasteque::PastequeIntegration.fetch_category(token).execute do |c|
        c.success do |r|
          puts r.inspect.yellow
          r.list.each do |category|
            puts category.inspect.green
            create_or_update_category(category)
            # get product for this category and create/update it
            Pasteque::PastequeIntegration.fetch_product_by_category(category[:id], r.token).execute do |c|
              c.success do |r|
                self.token = r.token
                r.list.each do |product|
                  puts product.inspect.green
                  create_or_update_variant(product, category[:id])
                end
              end
            end
          end
        end
      end

      # get taxes
      Pasteque::PastequeIntegration.fetch_taxes(token).execute do |c|
        c.success do |r|
          self.token = r.token
          r.list.each do |tax|
            puts tax.inspect.green
            create_or_update_tax(tax)
          end
        end
      end

      # get cash register (aka cashes)
      Pasteque::PastequeIntegration.fetch_cash_registers(token).execute do |c|
        c.success do |r|
          self.token = r.token
          r.list.each do |cash_register|
            puts cash_register.inspect.yellow
            # create_or_update_cash(cash_register)
            # get all payment mode (aka incoming_payment mode) for each cashes and create it in Ekylibre
            Pasteque::PastequeIntegration.fetch_payment_modes(token).execute do |c|
              c.success do |r|
                self.token = r.token
                r.list.each do |payment_mode|
                  puts payment_mode.inspect.yellow
                  #create_or_update_incoming_payment_mode(payment_mode, cash_register)
                end
              end
            end
          end
        end
      end

      # get all ticket
      Pasteque::PastequeIntegration.fetch_tickets(token).execute do |c|
        c.success do |r|
          self.token = r.token
          r.list.each do |ticket|
            puts ticket.inspect.yellow
            #create_or_update_ticket()
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
    #TODO create or update price for variant
  end

  def create_or_update_tax(tax)
    taxe = Tax.where("provider ->> 'vendor' = ? AND (provider ->> 'id')::int = ?", VENDOR, tax[:id]).first
    if taxe
      taxe.name = tax[:name]
      pnc.save!
    else
      tax_ref = Nomen::Tax.where(amount: tax[:rate] * 100, country: :fr).first
      if tax_ref
        taxe = Tax.import_from_nomenclature(tax_ref.name, true)
        taxe.name = tax[:name]
        taxe.description = "Pasteque"
        taxe.provider = {vendor: VENDOR, id: tax[:id]}
        taxe.save!
      else
        raise StandardError.new("Can not find tax in reference for #{tax[:name]} having rate : #{tax[:rate]}")
      end
    end
  end

  def create_or_update_incoming_payment_mode(payment_mode, cash_register)
    #TODO create or update incoming_payment_mode
  end

  def create_or_update_cash(cash_register)
    #TODO create or update cash
  end
end
