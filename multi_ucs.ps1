Install-Module -Name Cisco.UcsManager -Scope CurrentUser 
Import-Module -Name Cisco.UcsManager

$cred=Get-Credential svcautomation|Export-Clixml -Path "\\bb-nas\homedrives\id889974\Desktop\UCS\CRED.xml"  #Storing Credentials on Xmls file secutily
$credim=Import-Clixml -Path "\\bb-nas\homedrives\id889974\Desktop\UCS\CRED.xml" #Importing the secure stored password
$ucsips=@("192.168.127.12","192.168.127.22","10.120.24.103","10.120.25.103") #list of ucs ip's
foreach($ucsip in $ucsips){
        try{
    
        $connect_ucs=Connect-Ucs -Name $ucsip -Credential $credim  #Connection Establishment
        $ucs_name=$connect_ucs.Uri
        $chassis_list=Get-UcsChassis #List of Chassis
        $bladedata=@()
        $server_state=@()
        $Chassis=@()
        $result=@()
        $bnm=@()
        
                $date=Get-Date 
                $filestring=$date.ToString("yyyy_MM_dd_HH") 
                $Servers=Get-UcsChassis|Select-Object -ExpandProperty Id
                for($i=0;$i -lt $Servers.Length;$i++)
                {

                    #UCS Details.
                    $Blade=Get-UcsBlade -ChassisId $Servers[$i] #Gets the servers(blade) list for each chassis
                    $Chassisdata=Get-UcsBlade -ChassisId $Servers[$i]|Select-Object -ExpandProperty ChassisId 
                    $bladedata=Get-UcsBlade -ChassisId $Servers[$i]|Select-Object -ExpandProperty Rn
                    $server_state=Get-UcsBlade -ChassisId $Servers[$i]|Select-Object -ExpandProperty OperState

                    #Fault Data
                    $Fault_type=Get-UcsFault|Select-Object -ExpandProperty Severity            
                    $Fault_Descr=Get-UcsFault|Select-Object -ExpandProperty Descr
                    $Fault_Cause=Get-UcsFault|Select-Object -ExpandProperty Cause

                    #FABRICINTERCONNETOR
                    $FabricA_LEADER=(Get-UcsStatus).FiALeadership
                    $FabricB_LEADER=(Get-UcsStatus).FiBLeadership
                    $FabricA=Get-UcsNetworkElement -Id A
                    $FabricB=Get-UcsNetworkElement -Id B

                    #lastbackup
                    $ConfigBackupDetails=(Get-UcsMgmtBackupPolicyConfig).BackupDate

                    $bm=[PSCustomObject]@{                                                                            
                        Ucs_ip=$ucs_name
                        Chassis_Data=(@($Chassisdata)|Out-String).Trim()
                        Blades_Servers=(@($bladedata)|Out-String).Trim()
                        ServerState=(@($server_state)|Out-String).Trim()
 				        FabricInterconnect_A= "FabricInterconnect "+$FabricA.Id + $FabricA_LEADER
                        FabricA_OperableStatus=$FabricA.Operability
                        FabricA_Ethernet=Get-UcsLanCloud|Select-Object -ExpandProperty Mode
                        FabricA_FC_status=Get-UcsSanCloud|Select-Object -ExpandProperty Mode
                        FabricInterconnect_B= "FabricInterconnect "+$FabricB.Id + $FabricB_LEADER
                        FabricB_OperableStatus=$FabricB.Operability
                        FabricB_Ethernet=Get-UcsLanCloud|Select-Object -ExpandProperty Mode
                        FabricB_FC_status=Get-UcsSanCloud|Select-Object -ExpandProperty Mode 
                        EntireINFRA_config_backup= "Last Backup dated on " + $ConfigBackupDetails                                      
                        }

                        $result+=$bm

               
                 }
                 $bn=[PSCustomObject]@{
                Fault_Type=(@($Fault_type)|Out-String).Trim()
                Fault_Description=(@($Fault_Descr)|Out-String).Trim()
                Fault_Cause=(@($Fault_Cause)|Out-String).Trim()
                }
                $bnm+=$bn
               
                $result|Export-Excel "\\bb-nas\homedrives\id889974\Desktop\UCS\Capacit_Report$filestring.xlsx" -AutoSize -AutoFilter  -Append -WorksheetName "UCS_$ucsip" -BoldTopRow 
        
                $bnm|Export-Excel "\\bb-nas\homedrives\id889974\Desktop\UCS\Capacit_Report$filestring.xlsx" -AutoSize -AutoFilter  -Append -WorksheetName "UCS_FAULTS_$ucsip" -BoldTopRow
  
        Disconnect-Ucs #Disconnect the ucs connection

        }
        
        catch
        {
            Write-Host "Failed to connect to Ucs Manager on $ucsip.Error $_.Exception.Message"
        }

}
Disconnect-Ucs #Double checking and disconnecting the ucs ip.