
local LrFunctionContext = import 'LrFunctionContext'


require 'Panorama'

local function make_panorama(context)
  exportmap = export(context)
  make_project(context, exportmap)
  analyze(context)
  stitch(context)
end

LrFunctionContext.postAsyncTaskWithContext('make_panorama', make_panorama)

