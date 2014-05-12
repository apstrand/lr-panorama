
local LrFunctionContext = import 'LrFunctionContext'

require 'Panorama'

local function export_and_make(context)
  exportmap = export(context)
  make_project(context, exportmap)
end

LrFunctionContext.postAsyncTaskWithContext('export', export_and_make)


