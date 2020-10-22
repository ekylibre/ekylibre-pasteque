Rails.application.routes.draw do

  # namespace :backend, only: :list_links do
  #   resources :products do
  #     member do
  #       get :list_links
  #     end
  #   end
  # end


  concern :list do
    get :list, on: :collection
  end

  namespace :backend do
    resources :sale_tickets, concerns: %i[list], only: %i[index show destroy]
  end

end
