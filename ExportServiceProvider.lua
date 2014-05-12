
local LrLogger = import 'LrLogger'

local logger = LrLogger( 'exportLogger' )
logger:enable( "print" ) -- Pass either a string or a table of actions.


local function log( message )
  logger:trace( " PanoExport: " .. message )	
end



return {

  startDialog = function(propertyTable)
    log("startDialog: ")
  end,

  endDialog = function(propertyTable, why)
    log("endDialog: " .. why)
  end,

  exportPresetFields = {
    { key = 'myPluginSetting', default = 'Initial value' }
  },

  showSections = { 'exportLocation', 'fileNaming', 'imageSettings' },

  updateExportSettings = function (exportSettings)
    log("updateExportSettings: " .. exportSettings)
    exportSettions['LR_collisionHandling'] = 'overwrite'
  end,

  processRenderedPhotos = function(functionContext, exportContext)
    local exports = { }
    for i,rendition in exportContext:renditions() do
      local success, pathOrMessage = rendition:waitForRender()
      log("rendition " .. i .. " " .. tostring(success) .. " " .. pathOrMessage)
      table.insert(exports, pathOrMessage)
    end
    log("photos: " .. tostring(exports))
  end
}
