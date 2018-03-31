# ===== Change these as needed =====
$logFileDir = "C:\local\var\tmp\test"
$logFilePattern = "trace*.log"
#$logFilePattern = "SystemOut*.log"
$progressFile = "C:\local\var\tmp\test\progress.txt"
$matchString = "SECJ0373E"
$smtpServer	= "smtp.notes.na.collabserv.com"
$recipientAddress = "chads@us.ibm.com"
$senderAddress = "cs-alerts@us.ibm.com"
$subject = "New alert at "
$debug = $false

# ===== Don't change these =====
$lastTimestampProcessed	= $null
$timestampRegex	= "([1-9]|1[012])/([0-9]|1[0-9]|2[0-9]|3[01])/([0-9][0-9]) ([0-9]|1[0-9]|2[01234]):([012345][0-9]):([012345][0-9]):([0-9][0-9][0-9])"
$timeFormat	= "M/d/yy H:mm:ss:fff"
$sendEmail = $false
$body = $null

function log {
    param([string]$text)
    Write-Host $text
}

function debug {
    param([string]$text)
    if ($debug -eq $true) {
        Write-Host $text
    }
}

# Get the log files
$logFiles = Get-ChildItem "$logFileDir\$logFilePattern"

# Exit if there are no log files
if ( $($logFiles | Measure-Object).Count -eq 0 ) {
    log("No log files found matching pattern $logFileDir\$logFilePattern. Exiting")
    Exit
}

# Get the timestamp in progress.txt or create the file if it doesn't exist. Save the original value
# in case it needs to be reverted due to error sending alert email. Note that it is a string object here.
if (Test-Path $progressFile) {
	debug("Getting last processed timestamp from $progressFile")
	$lastTimestampProcessed = $originalLastTimestampProcessed = Get-Content $progressFile
} else {
	debug("Creating $progressFile")
	$null >> $progressFile
}

# See if there are any occurrences more recent than the last timestamp processed
ForEach ($logFile in $logFiles) {
    debug("Processing $logFile")
    Select-String $logFile -Pattern $matchString |
        ForEach {
	        $_.Line | Select-String -Pattern $timestampRegex | 
		        ForEach { 
			        $thisTimestamp = [datetime]::ParseExact($_.Matches[0].Value, $timeFormat, [System.Globalization.CultureInfo]::InvariantCulture)
			        if ($thisTimestamp -gt $lastTimestampProcessed) {
				        $lastTimestampProcessed = $thisTimestamp
				        debug("New most recent timestamp is $lastTimestampProcessed")
				        Set-Content $progressFile $lastTimestampProcessed.ToString("yyyy/MM/dd HH:mm:ss.fff")
				        $body = $_.Line
				        $sendEmail = $true
			        } else {
                        debug("Skipping match because timestamp $thisTimestamp is not more recent than $lastTimestampProcessed")
                    }
		        }
        }
}
		
# Send an email if necessary. In rare cases the message send will fail due to SMTP issues. In those cases, the progress file needs to be reset
# So any new watched messages that were found will trigger an alert on the next run
if ($sendEmail) {
	log("Sending email to $recipientAddress")
    Try {
	    Send-MailMessage -SmtpServer $smtpServer -To $recipientAddress -From $senderAddress -Subject "$subject $lastTimestampProcessed" -Body $body
    } Catch {
        if ($originalLastTimestampProcessed -eq $null) {
            log("Error sending email. Deleting progress file since there was no timestamp from a prior run")
            Remove-Item $progressFile
        } else {
            log("Error sending email. Reverting last timestamp")
            Set-Content $progressFile $originalLastTimestampProcessed
        }
    }
} else {
    log("No new alerts found")
}