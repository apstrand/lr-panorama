
local LrDialogs = import 'LrDialogs'
local LrLogger = import 'LrLogger'
local LrApplication = import 'LrApplication'
local LrTasks = import 'LrTasks'
local LrExportSession = import 'LrExportSession'
local LrFunctionContext = import 'LrFunctionContext'
local LrProgressScope = import 'LrProgressScope'
local LrShell = import 'LrShell'
local LrPathUtils = import 'LrPathUtils'

local myLogger = LrLogger( 'exportLogger' )
myLogger:enable( "print" ) -- Pass either a string or a table of actions.


local function log( message )
  myLogger:trace( " PanoExport: " .. message )	
end

function quote(str)
  return string.gsub(str, "[ ]+", "\\%1")
end

function concat_quote_args(args)
  local temp = { }
  for i, arg in ipairs(args) do
    local s = quote(arg)
    table.insert(temp, s)
  end
  return table.concat(temp, " ")
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

  local selected = catalog:getTargetPhoto()
  log("selected: " .. selected:getFormattedMetadata('fileName'))

  local stack = selected:getRawMetadata('stackInFolderMembers')
  log("stack: " .. #stack)

  for i,photo in ipairs(stack) do
    log("consider: " .. photo:getFormattedMetadata('fileName'))
    if photo:getRawMetadata('fileFormat') ~= 'TIFF' then
      table.insert(photos, {photo=photo,path = photo:getRawMetadata('path'), name = photo:getFormattedMetadata('fileName')})
    end
  end
  log("photos: " .. #photos)

  table.sort(photos, function(p1, p2)
    return p1.name < p2.name
  end)
  log("sorted: " .. #photos)
  proj=string.gsub(photos[1].name, "\.[^.]*$", "_pano", 1)
  path=LrPathUtils.parent(photos[1].photo:getRawMetadata('path'))
  log("proj: " .. proj)
  return path, proj, photos
end

function export(context)

  LrDialogs.attachErrorDialogToFunctionContext(context)

  local progressScope = LrProgressScope {
    title = 'Panorama export..',
    functionContext = context,
  }

  local proj_path,proj_name,photo_list = extract_proj_info()
  
  exports = { }
  exportmap = { }
  for i,photo in ipairs(photo_list) do
    table.insert(exports, photo.photo)
    exportmap[photo.photo] = { }
  end

  log("exports " .. #exports)
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
    log("export " .. proj_name .. ": " .. key:getFormattedMetadata('fileName') .. " -> " .. value['path'])
  end

  return exportmap
end

function make_project(context, exportmap)

  LrDialogs.attachErrorDialogToFunctionContext(context)

  local proj_path,proj_name,photo_list = extract_proj_info()

  exportpath = LrPathUtils.child(proj_path, exportSettings.LR_export_destinationPathSuffix)

  if exportmap == nil then
    exportmap = { }
    for i,photo in ipairs(photo_list) do
      local fake = LrPathUtils.replaceExtension(photo.name, "tif")
      local absfake = LrPathUtils.makeAbsolute(fake, exportpath)
      exportmap[photo] = {path = absfake}
    end
  end
  log("map " .. #exportmap)
  
  local args = { }
  local path = _PLUGIN.path
  cmd = LrPathUtils.child(path, "pano_gen")
  table.insert(args, cmd)
  table.insert(args, proj_path)
  table.insert(args, proj_name)

  files = { }
  for key,photo in pairs(exportmap) do
    log("add " .. photo.path)
    table.insert(args, photo.path)
  end

  log("cmd " .. concat_quote_args(args))
  local cmdline = concat_quote_args(args)
  LrTasks.execute(cmdline)

end

function analyze(context)

  LrDialogs.attachErrorDialogToFunctionContext(context)

  local progressScope = LrProgressScope {
    title = 'Panorama analyzing..',
    functionContext = context,
  }

  local proj_path,proj_name,photo_list = extract_proj_info()

  local args = { }
  local path = _PLUGIN.path
  cmd = LrPathUtils.child(path, "pano_analyze")
  table.insert(args, cmd)
  table.insert(args, proj_path)
  table.insert(args, proj_name)

  local cmdline = concat_quote_args(args)
  LrTasks.execute(cmdline)
end

function stitch(context)
  LrDialogs.attachErrorDialogToFunctionContext(context)

  local progressScope = LrProgressScope {
    title = 'Panorama stitching..',
    functionContext = context,
  }

  local proj_path,proj_name,photo_list = extract_proj_info()

  local args = { }
  local path = _PLUGIN.path
  cmd = LrPathUtils.child(path, "pano_stitch")
  table.insert(args, cmd)
  table.insert(args, proj_path)
  table.insert(args, proj_name)
  table.insert(args, LrPathUtils.child(proj_path, exportSettings.LR_export_destinationPathSuffix))

  local cmdline = concat_quote_args(args)
  LrTasks.execute(cmdline)

  local catalog = LrApplication:activeCatalog()
  local pano_path = LrPathUtils.child(proj_path, proj_name .. ".tif")
  log("adding " .. pano_path)
  if catalog:findPhotoByPath(pano_path) == nil then
    catalog:withWriteAccessDo("add panorama", function(context)
      catalog:addPhoto(pano_path, photo_list[1].photo, 'above')
    end)
  end

end

