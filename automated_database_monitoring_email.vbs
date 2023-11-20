Set emailObj      = CreateObject("CDO.Message")
emailObj.From     = "shayan.choudhury@<email>.com"
emailObj.To       = "shayan.choudhury@<email>.com"
emailObj.Subject  = "DATABASE MONITORING REPORT"
emailObj.TextBody = "The following attachment outlines the disk space usage by the different databases and also the amount of space used at the database level. 
It also contains the names of 30 Tables(10 tables from each database) that haven't been modified in the last 180 days and may be deleted subject to review.
The F:\ drive contains the master and tempdb databases and the script mentions the disk space usage and action should be taken if F:\ drive disk space usage is extremely high and temp files should be deleted.
"

emailObj.AddAttachment "C:\Users\schoud1\Desktop\database_monitoring_status.txt"

Set emailConfig = emailObj.Configuration

emailConfig.Fields("http://schemas.microsoft.com/cdo/configuration/smtpserver") = "smtp.office365.com"
emailConfig.Fields("http://schemas.microsoft.com/cdo/configuration/smtpserverport") = 25
emailConfig.Fields("http://schemas.microsoft.com/cdo/configuration/sendusing")    = 2  
emailConfig.Fields("http://schemas.microsoft.com/cdo/configuration/smtpauthenticate") = 1  
'emailConfig.Fields("http://schemas.microsoft.com/cdo/configuration/smtpusessl")      = true 
emailConfig.Fields("http://schemas.microsoft.com/cdo/configuration/sendusername")    = "shayan.choudhury@morningstar.com"
emailConfig.Fields("http://schemas.microsoft.com/cdo/configuration/sendpassword")    = "grEatlygreat0705"
emailConfig.Fields.Update

emailObj.Send

If err.number = 0 then Msgbox "Done"