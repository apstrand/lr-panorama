
return {
  LrSdkVersion = 5.0,
  LrSdkMinimumVersion = 5.0,
  LrToolkitIdentifier = 'se.zarquon.panoexport',
  LrPluginName = LOC "$$$/PanoramaExport/PluginName=Panorama Export",
  LrExportServiceProvider = {
    title = "Panorama Export Service",
    file = "ExportServiceProvider.lua",
  },

  LrExportMenuItems = {
    {
      title = "Make Panorama",
      file = "PanoMake.lua",
    },
    {
      title = "Panorama Export",
      file = "PanoExport.lua",
    },
    {
      title = "Panorama Proj",
      file = "PanoProj.lua",
    },
    {
      title = "Panorama Analyze",
      file = "PanoAnalyze.lua",
    },
    {
      title = "Panorama Stitch",
      file = "PanoStitch.lua",
    },
    {
      title = "Hugin",
      file = "Hugin.lua",
    },
  },

  VERSION = { major=0, minor=0, revision=1, build=1, },
}

