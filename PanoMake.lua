
local LrFunctionContext = import 'LrFunctionContext'
local LrApplication = import 'LrApplication'

local catalog = LrApplication:activeCatalog()

require 'Panorama'

local function make_panorama(context)
  local selected = catalog:getTargetPhoto()
  exportmap = export(context, selected)
  make_project(context, exportmap, selected)
  analyze(context, selected)
  stitch(context, selected)
end

LrFunctionContext.postAsyncTaskWithContext('make_panorama', make_panorama)

