module EkylibrePasteque
  class Engine < ::Rails::Engine

  	initializer 'planning.assets.precompile' do |app|
      app.config.assets.precompile += %w( integrations/pasteque.png )
    end

    initializer :i18n do |app|
      app.config.i18n.load_path += Dir[EkylibrePasteque::Engine.root.join('config', 'locales', '**', '*.yml')]
    end

    initializer :extend_navigation do |_app|
      EkylibrePasteque::ExtNavigation.add_navigation_xml_to_existing_tree
    end

    initializer :extend_controllers do |app|
      app.config.paths['app/views'].unshift EkylibrePasteque::Engine.root.join('app/views').to_s
    end

  end
end
