
local LrFunctionContext = import 'LrFunctionContext'


require 'Panorama'

local function make_panorama(context)
  export(context)
  make_panorama(context)
  analyze(context)
  stitch(context)
end

LrFunctionContext.postAsyncTaskWithContext('make_panorama', make_panorama)

