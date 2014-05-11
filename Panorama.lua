
local LrDialogs = import 'LrDialogs'
local LrLogger = import 'LrLogger'
local LrApplication = import 'LrApplication'
local LrTasks = import 'LrTasks'
local LrExportSession = import 'LrExportSession'
local LrFunctionContext = import 'LrFunctionContext'
local LrProgressScope = import 'LrProgressScope'

local myLogger = LrLogger( 'exportLogger' )
myLogger:enable( "print" ) -- Pass either a string or a table of actions.


local function log( message )
  myLogger:trace( " PanoExport: " .. message )	
end

local exportSettings = {
--  LR_export_destinationPathPrefix = '/Users/peter/Pictures/PanoExport/',
--  LR_export_destinationType = "specificFolder",
  LR_collisionHandling = "overwrite",
  LR_embeddedMetadataOption = "all",
  LR_exportServiceProvider = "com.adobe.ag.export.file",
  LR_exportServiceProviderTitle = "Hard Drive",
  LR_export_bitDepth = 16,
  LR_export_colorSpace = "AdobeRGB",
  LR_export_destinationPathSuffix = "__PanoramaTemp",
  LR_export_destinationType = "sourceFolder",
  LR_export_useSubfolder = true,
  LR_export_videoFileHandling = "include",
  LR_export_videoFormat = "4e49434b-4832-3634-fbfb-fbfbfbfbfbfb",
  LR_export_videoPreset = "original",
  LR_extensionCase = "lowercase",
  LR_format = "TIFF",
  LR_includeFaceTagsAsKeywords = true,
  LR_includeVideoFiles = true,
  LR_initialSequenceNumber = 1,
  LR_metadata_keywordOptions = "flat",
  LR_outputSharpeningOn = false,
  LR_reimportExportedPhoto = false,
  LR_removeFaceMetadata = true,
  LR_removeLocationMetadata = false,
  LR_renamingTokensOn = false,
  LR_size_doConstrain = false,
  LR_size_resolution = 240,
  LR_size_resolutionUnits = "inch",
  LR_tiff_compressionMethod = "compressionMethod_ZIP",
  LR_tiff_preserveTransparency = false,
  LR_tokenCustomString = "",
  LR_tokens = "{{image_name}}",
  LR_tokensArchivedToString2 = "{{image_name}}",
  LR_useWatermark = false,

}

function extract_proj_info()
  local catalog = LrApplication:activeCatalog()
  local photos = { }

  return "apa", photos
end

function export(context)

  LrDialogs.attachErrorDialogToFunctionContext(context)

  local progressScope = LrProgressScope {
    title = 'Panorama export..',
    functionContext = context,
  }

  local proj_name,photo_list = extract_proj_info()
  LrDialogs.message("Panorama: " .. proj_name .. " photos " .. #photo_list)
  
  local catalog = LrApplication:activeCatalog()

  local photos = catalog:getMultipleSelectedOrAllPhotos()
  log("photos " .. #photos)

  panos = { }
  for i,photo in ipairs(photos) do
    local name = photo:getFormattedMetadata('fileName')
    local is_stack = photo:getRawMetadata('isInStackInFolder') -- isInStackInFolder')
    local is_collapsed = photo:getRawMetadata('stackInFolderIsCollapsed')
    if is_stack and not is_collapsed then
      local top = photo:getRawMetadata('topOfStackInFolderContainingPhoto')
      log("pano: " .. photo:getFormattedMetadata('fileName') .. " top: " .. top:getFormattedMetadata('fileName'))
      if not panos[top] then
        panos[top] = { }
      end
      table.insert(panos[top], photo)
    end
  end

  local exports = { }
  local exportmap = { }
  table.foreach(panos, function (top,parts)
    log("parts " .. tostring(parts) .. " " .. #parts)
    for i,part in ipairs(parts) do
      exportmap[part] = { }
      exportmap[part]['top'] = top
      table.insert(exports, part)
    end
  end)

  local exportSession = LrExportSession{
    exportSettings = exportSettings,
    photosToExport = exports,
  }

  for i,rendition in exportSession:renditions() do
    local success, pathOrMessage = rendition:waitForRender()
    log("rendition " .. i .. " " .. pathOrMessage)
    exportmap[rendition.photo]['path'] = pathOrMessage
  end

  for key,value in pairs(exportmap) do
    log("export " .. key:getFormattedMetadata('fileName') .. " -> " .. value['top']:getFormattedMetadata('fileName') .. ' ' .. value['path'])
  end

end


function make_project(context)


end

function analyze(context)

end

function stitch(context)

end

