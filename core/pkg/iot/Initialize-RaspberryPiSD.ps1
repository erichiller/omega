# function Initialize-RaspPiSD {

	param(
		[string] $ssid,
		[string] $pass
	)
	
	
	get-disk | ForEach-Object {
	
		Write-Output "$($_.UniqueId) ( $($_.UniqueIdFormat) )"
		if ( $_.UniqueId -like "USBSTOR*" -and $_.PartitionStyle -eq "MBR" ) {
	
			Write-Output "`tIS USB STORE and MBR"
			Get-Partition -DiskPath $_.Path | ForEach-Object {
				if ( $_.Type -like "*FAT32*") {
	
					Write-Output "`t$($_.DriveLetter) IS FAT32"
	
					if ( $(Read-Host -Prompt "Continue with Drive $($_.DriveLetter) (y/n) ?") -like "y*" ) {

						$wifiConfig = @"
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
	ssid="$ssid"
	psk="$pass"
}


"@
	
						Write-Output "Setting $($_.DriveLetter)..."
						Set-Content -Path "$($_.DriveLetter):\ssh" -Value ""
						Set-Content -Path "$($_.DriveLetter):\wpa_supplicant.conf" -Value $wifiConfig
	
	
						if ( Read-Host -Prompt "Dismount $($_.DriveLetter) (y/n) ?" ) {
							$driveLetter = "$($_.DriveLetter):\";
							$Eject = New-Object -comObject Shell.Application    
							$Eject.NameSpace(17).ParseName($driveLetter).InvokeVerb("Eject")
	
						}
	
	
					}
	
	
				}
	
			}
		} else {
			Write-Output "`tNOT A US"A
		}
	}
	
#}
