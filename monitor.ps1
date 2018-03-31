# Change these as needed
$logFile								= "C:\local\var\tmp\test\trace.log"
$progressFile						= "C:\local\var\tmp\test\progress.txt"
$matchString						= "SECJ0373E"
$smtpServer							= "smtp.notes.na.collabserv.com"
$recipientAddress					= "chads@us.ibm.com"
$senderAddress						= "cs-alerts@us.ibm.com"
$subject								= "New alert at "
$body									= 
# Don't change these
$lastTimestampProcessed			= $null
$timestampRegex					= "([1-9]|1[012])/([0-9]|1[0-9]|2[0-9]|3[01])/([0-9][0-9]) ([0-9]|1[0-9]|2[01234]):([012345][0-9]):([012345][0-9]):([0-9][0-9][0-9])"
$timeFormat							= "M/d/yy H:mm:ss:fff"
$sendEmail							= $false

# Ensure logFile exists
if (!(Test-Path ${logFile})) {
	Write-Host "${logFile} does not exist. Exiting"
	exit
}

# Get the timestamp in progress.txt or create the file if it doesn't exist
if (Test-Path ${progressFile}) {
	Write-Host "Getting last processed timestamp from ${progressFile}"
	$lastTimestampProcessed = Get-Content ${progressFile}
} else {
	Write-Host "Creating ${progressFile}"
	$null >> ${progressFile}
}

# See if there are any occurrences more recent than the last timestamp processed
Select-String ${logFile} -Pattern ${matchString} |
		ForEach {
			$_.Line | Select-String -Pattern ${timestampRegex} | 
				ForEach { 
					$thisTimestamp = [datetime]::ParseExact($_.Matches[0].Value, ${timeFormat}, [System.Globalization.CultureInfo]::InvariantCulture)
					if (${thisTimestamp} -gt ${lastTimestampProcessed}) {
						$lastTimestampProcessed = ${thisTimestamp}
						Write-Host "New most recent timestamp is ${lastTimestampProcessed}"
						Set-Content ${progressFile} ${lastTimestampProcessed}.ToString("yyyy/MM/dd HH:mm:ss.fff")
						$body = $_.Line
						$sendEmail = $true
					}
				}
		}
		
# Send an email if necessary
if ($sendEmail) {
	Write-Host "Sending email to ${recipientAddress}"
	Send-MailMessage -SmtpServer ${smtpServer} -To ${recipientAddress} -From ${senderAddress} -Subject "${subject} ${lastTimestampProcessed}" -Body ${body}
}