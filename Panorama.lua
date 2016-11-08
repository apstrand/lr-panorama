
local LrDialogs = import 'LrDialogs'
local LrLogger = import 'LrLogger'
local LrApplication = import 'LrApplication'
local LrTasks = import 'LrTasks'
local LrExportSession = import 'LrExportSession'
local LrFunctionContext = import 'LrFunctionContext'
local LrProgressScope = import 'LrProgressScope'
local LrShell = import 'LrShell'
local LrPathUtils = import 'LrPathUtils'
local LrFileUtils = import 'LrFileUtils'

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

local hugin_path = "/Applications/Hugin/Hugin.app"

local catalog = LrApplication:activeCatalog()
local catalog_folder = LrPathUtils.parent(catalog:getPath())
local temp_folder = LrPathUtils.child(catalog_folder, "PanoramaTemp")

local exportSettings = {
  LR_collisionHandling = "overwrite",
  LR_embeddedMetadataOption = "all",
  LR_exportServiceProvider = "com.adobe.ag.export.file",
  LR_exportServiceProviderTitle = "Hard Drive",
  LR_export_bitDepth = 16,
  LR_export_colorSpace = "AdobeRGB",
  LR_export_destinationPathPrefix = temp_folder,
  LR_export_destinationType = "specificFolder",
  LR_export_useSubfolder = false,
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

function extract_proj_info(selected)
  local catalog = LrApplication:activeCatalog()
  local photos = { }

  if selected == nil then
    selected = catalog:getTargetPhoto()
  end
  log("selected: " .. selected:getFormattedMetadata('fileName'))

  local stack = selected:getRawMetadata('stackInFolderMembers')

  for i,photo in ipairs(stack) do
    if not string.find(photo:getFormattedMetadata('fileName'), "panorama") then
      log("insert: " .. photo:getRawMetadata('path'))
      table.insert(photos, {photo=photo,path = photo:getRawMetadata('path'), name = photo:getFormattedMetadata('fileName')})
    end
  end

  table.sort(photos, function(p1, p2)
    return p1.name < p2.name
  end)
  local proj_suffix = "_" .. #photos .. "_pano"
  log("photos: " .. #photos)
  proj=string.gsub(photos[1].name, "\.[^.]*$", proj_suffix, 1)
  path=LrPathUtils.parent(photos[1].photo:getRawMetadata('path'))
  log("proj: " .. proj)
  return path, proj, photos
end

function export(context, selected)

  LrDialogs.attachErrorDialogToFunctionContext(context)

  local progress = LrProgressScope {
    title = 'Panorama export..',
    functionContext = context,
  }


  pcall(LrFileUtils.createDirectory, temp_folder)

  local proj_path,proj_name,photo_list = extract_proj_info(selected)
  
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
    if rendition.photo == nil then
      log(" rendition.photo is nil!")
    else
      exportmap[rendition.photo]['path'] = pathOrMessage
    end
  end

  for key,value in pairs(exportmap) do
    log("export " .. proj_name .. ": " .. key:getFormattedMetadata('fileName') .. " -> " .. value['path'])
  end

  progress:done()
  return exportmap
end

function make_project(context, exportmap, selected)

  LrDialogs.attachErrorDialogToFunctionContext(context)

  local proj_path,proj_name,photo_list = extract_proj_info(selected)

  exportpath = temp_folder

  if exportmap == nil then
    exportmap = { }
    for i,photo in ipairs(photo_list) do
      local fake = LrPathUtils.replaceExtension(photo.name, "tif")
      local absfake = LrPathUtils.makeAbsolute(fake, exportpath)
      exportmap[photo] = {path = absfake}
    end
  end
  
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

  local cmdline = concat_quote_args(args)
  log("cmd " .. cmdline)
  LrTasks.execute(cmdline)
  log("done")

end

function analyze(context, selected)

  LrDialogs.attachErrorDialogToFunctionContext(context)

  local progress = LrProgressScope {
    title = 'Panorama analyzing..',
    functionContext = context,
  }

  local proj_path,proj_name,photo_list = extract_proj_info(selected)

  local args = { }
  local path = _PLUGIN.path
  cmd = LrPathUtils.child(path, "pano_analyze")
  table.insert(args, cmd)
  table.insert(args, proj_path)
  table.insert(args, proj_name)

  local cmdline = concat_quote_args(args)
  log("cmd " .. cmdline)
  LrTasks.execute(cmdline)
  progress:done()
end

function stitch(context, selected)
  LrDialogs.attachErrorDialogToFunctionContext(context)

  local progress = LrProgressScope {
    title = 'Panorama stitching..',
    functionContext = context,
  }

  local proj_path,proj_name,photo_list = extract_proj_info(selected)

  local args = { }
  local path = _PLUGIN.path
  cmd = LrPathUtils.child(path, "pano_stitch")
  table.insert(args, cmd)
  table.insert(args, proj_path)
  table.insert(args, proj_name)
  table.insert(args, temp_folder)

  local cmdline = concat_quote_args(args)
  log("cmd " .. cmdline)
  LrTasks.execute(cmdline)

  local catalog = LrApplication:activeCatalog()
  local pano_path = LrPathUtils.child(proj_path, proj_name .. "rama.jpeg")
  local base_path = photo_list[1].path

  log("fixup " .. pano_path .. " from " .. base_path)
  cmd = LrPathUtils.child(path, "pano_fixup")
  args = { }
  table.insert(args, cmd)
  table.insert(args, base_path)
  table.insert(args, pano_path)
  cmdline = concat_quote_args(args)
  log("cmd " .. cmdline)
  LrTasks.execute(cmdline)


  log("adding " .. pano_path)

  local pano_photo = catalog:findPhotoByPath(pano_path)
  if pano_photo == nil then
    catalog:withWriteAccessDo("add panorama", function(context)
      pano_photo = catalog:addPhoto(pano_path, photo_list[1].photo, 'above')
    end, { timeout = 10 })
  end

  progress:done()
end

function hugin(context, selected)
  
  LrDialogs.attachErrorDialogToFunctionContext(context)

  local proj_path,proj_name,photo_list = extract_proj_info(selected)

  local proj_file = LrPathUtils.addExtension(LrPathUtils.child(proj_path, proj_name), "pto")
  LrTasks.execute("open -a Hugin " .. quote(proj_file))

end

