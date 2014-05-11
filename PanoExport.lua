
local LrFunctionContext = import 'LrFunctionContext'

require 'Panorama'

local function export_and_make(context)
  export(context)
  make_project(context)
end

LrFunctionContext.postAsyncTaskWithContext('export', export_and_make)


