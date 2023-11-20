$emailSmtpServer = "smtp.office365.com"
$emailSmtpServerPort = "25"
$emailSmtpUser = "shayan.choudhury@<email>.com"
$emailSmtpPass = "###"
 
$emailFrom = "shayan.choudhury@<email>.com"
$emailTo = "shayan.choudhury@<email>.com"
$emailcc="sandeep@<email>.com"
 
$file = "..\DB_MONITORING\database_monitoring_status.txt"
$emailMessage = New-Object System.Net.Mail.MailMessage( $emailFrom , $emailTo )
$emailMessage.Attachments.Add($file)
                             
$emailMessage.cc.add($emailcc)
$emailMessage.Subject = "DATABASE MONITORING REPORT"
#$emailMessage.IsBodyHtml = $true #true or false depends
$emailMessage.Body = "The following attachment outlines the disk space usage by the different databases and also the amount of space used at the database level. 
It also contains the names of 30 Tables(10 tables from each database) that haven't been modified in the last 180 days and may be deleted subject to review.
The F:\ drive contains the master and tempdb databases and the script mentions the disk space usage and action should be taken if F:\ drive disk space usage is extremely high and temp files should be deleted.
"
 
$SMTPClient = New-Object System.Net.Mail.SmtpClient( $emailSmtpServer , $emailSmtpServerPort )
$SMTPClient.EnableSsl = $true
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential( $emailSmtpUser , $emailSmtpPass );
$SMTPClient.Send( $emailMessage )