master.dbo.xp_cmdshell 'net start sqlserveragent'

BEGIN TRANSACTION            
  DECLARE @JobID BINARY(16)  
  DECLARE @ReturnCode INT    
  SELECT @ReturnCode = 0     
IF (SELECT COUNT(*) FROM msdb.dbo.syscategories WHERE name = N'[Uncategorized (Local)]') < 1 
  EXECUTE msdb.dbo.sp_add_category @name = N'[Uncategorized (Local)]'

  -- 刪除同名的警報（如果有的話）。
  SELECT @JobID = job_id     
  FROM   msdb.dbo.sysjobs    
  WHERE (name = N'下載最新超級舞者道具列表')       
  IF (@JobID IS NOT NULL)    
  BEGIN  
  -- 檢查此作業是否為多重伺服器作業  
  IF (EXISTS (SELECT  * 
              FROM    msdb.dbo.sysjobservers 
              WHERE   (job_id = @JobID) AND (server_id <> 0))) 
  BEGIN 
    -- 已經存在，因而終止腳本 
    RAISERROR (N'無法導入作業“下載最新超級舞者道具列表”，因為已經有相同名稱的多重伺服器作業。', 16, 1) 
    GOTO QuitWithRollback  
  END 
  ELSE 
    -- 刪除［本地］作業 
    EXECUTE msdb.dbo.sp_delete_job @job_name = N'下載最新超級舞者道具列表' 
    SELECT @JobID = NULL
  END 

BEGIN 

  -- 添加作業
  EXECUTE @ReturnCode = msdb.dbo.sp_add_job @job_id = @JobID OUTPUT , @job_name = N'下載最新超級舞者道具列表', @owner_login_name = N'sa', @description = N'沒有可用的描述。', @category_name = N'[Uncategorized (Local)]', @enabled = 1, @notify_level_email = 0, @notify_level_page = 0, @notify_level_netsend = 0, @notify_level_eventlog = 2, @delete_level= 0
  IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback 

  -- 添加作業步驟
  EXECUTE @ReturnCode = msdb.dbo.sp_add_jobstep @job_id = @JobID, @step_id = 1, @step_name = N'download', @command = N'execute SDO_ItemData_Down', @database_name = N'GMTOOLS', @server = N'', @database_user_name = N'', @subsystem = N'TSQL', @cmdexec_success_code = 0, @flags = 0, @retry_attempts = 0, @retry_interval = 1, @output_file_name = N'', @on_success_step_id = 0, @on_success_action = 1, @on_fail_step_id = 0, @on_fail_action = 2
  IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback 
  EXECUTE @ReturnCode = msdb.dbo.sp_update_job @job_id = @JobID, @start_step_id = 1 

  IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback 

  -- 添加作業調度
  EXECUTE @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id = @JobID, @name = N'week', @enabled = 1, @freq_type = 8, @active_start_date = 20060429, @active_start_time = 90000, @freq_interval = 2, @freq_subday_type = 1, @freq_subday_interval = 0, @freq_relative_interval = 0, @freq_recurrence_factor = 1, @active_end_date = 99991231, @active_end_time = 235959
  IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback 

  -- 添加目標伺服器
  EXECUTE @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @JobID, @server_name = N'(local)' 
  IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback 

END
COMMIT TRANSACTION          
GOTO   EndSave              
QuitWithRollback:
  IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION 
EndSave: 





