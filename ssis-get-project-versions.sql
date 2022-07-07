USE SSISDB
GO

SELECT folders.name [Folder Name]
      ,projects.name [Project Name]
      ,packages.name [Package Name]
      ,version_major [Version Major]
      ,version_minor [Version Minor]
      ,version_build [Version Build]
      ,project_version_lsn [Project LSN]
      ,object_versions.created_time [Installed]
      ,IIF(object_versions.object_version_lsn=projects.object_version_lsn,'Yes','No') [Latest Version?]
FROM    internal.packages
JOIN    internal.projects
ON      projects.project_id=packages.project_id
JOIN    internal.object_versions
ON      object_versions.object_id=projects.project_id
AND     object_versions.object_version_lsn=packages.project_version_lsn
JOIN    internal.folders
ON      folders.folder_id=projects.folder_id
ORDER BY projects.name,packages.name,version_build DESC,project_version_lsn DESC