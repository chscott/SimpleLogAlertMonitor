## Overview

SimpleLogAlertMonitor scans a set of WebSphere Application Server log files looking for a user-supplied pattern to trigger an email alert. On each run, the most recent occurrence found in the logs is compared to the last recorded 
occurrence to determine if it is new. If it is, an email is sent and the last recorded occurrence is updated. If it is not, no action is taken. 

The intended use case is to run the monitor as a scheduled task that is at least as frequent as the amount of time captured in the log set. For example, if logging is configured to create five logs of 20 MB each and that 100 total MB of available logging captures approximately one hour of activity, then the monitor would need to be scheduled to run at least every hour or events can be lost by cycling out of the logs before the monitor has had a chance to run.

Configurable options are noted at the top of the script. Those include:

- $logFileDir: Directory containing your WAS log files
- $logFilePattern: Pattern used to locate WAS log files. Select one and comment out the other
- $progressFile: File used to track the last timestamp that triggered an alert. This prevents multiple runs over the same set of log statements from generating multiple alerts
- $matchString: The string that determines if an alert should be fired
- $smtpServer: SMTP server used for send alert email
- $recipientAddress: Address of user who should receive alert emails
- $senderAddress: The sender on alert emails
- $subject: The subject on alert emails
- $debug: Set to $true to log monitor processing information when troubleshooting

## Prerequisites

- SimpleLogAlertMonitor is a PowerShell script and runs only on Windows. It has been tested on PowerShell version 5 only. If you encounter errors while running it, please ensure you are running version 5 or later as a first step. 
  To do that run the following command:

   ```PowerShell
   $PSVersionTable.PSVersion.Major
   ```

   If this returns a number less than 5, see <https://www.microsoft.com/en-us/download/details.aspx?id=50395> for details on downloading a Windows update to upgrade the version.
	
- Ensure your assigned policies permit running unsigned scripts. To check, run the following command:

   ```PowerShell
   Get-ExecutionPolicy -List
   ```
	
	See https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-executionpolicy?view=powershell-6 for details on policy options. SimpleLogAlertMonitor has been tested with the following configuration:
	
   - MachinePolicy: Undefined
   - UserPolicy: Undefined
   - Process: Undefined
   - CurrentUser: Undefined
   - LocalMachine: **Unrestricted**
	
- If you are using HPEL logging, you must also enable the option to create an HPEL text log. SimpleLogAlertMonitor does not monitor the binary HPEL format.