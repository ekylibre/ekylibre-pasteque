module Backend
  class SaleTicketsController < EkylibrePasteque::ApplicationController

    manage_restfully

    unroll

    def self.sale_tickets_conditions
      search_conditions(sale_tickets: [:name, :number])
    end

    list(conditions: sale_tickets_conditions) do |t|
      t.action :destroy, if: :destroyable?
      t.column :number, url: true
      t.column :name
    end
  end
end
