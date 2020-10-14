require "ekylibre-pasteque/engine"
require "ekylibre-pasteque/ext_navigation"


module EkylibrePasteque
  def self.root
    Pathname.new(File.dirname __dir__)
  end
end
