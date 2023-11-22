# c/o https://social.technet.microsoft.com/Forums/windows/en-US/53656137-de5c-4fad-b26f-925649aed2ad/how-to-get-contacts-from-active-directorys-distribution-group-in-csv-using-powershell?forum=winserverpowershell

Add-Type -AssemblyName System.Windows.Forms

Write-Output "Export AD Group User members"
Write-Output "`nThis script will create a CSV file containing name, mail, and parent OU, as well as a text file with email addresses."
Write-Output "`n"

$GroupName=Read-Host "Enter the name of the AD Group from which to export Users"

$dlg=New-Object System.Windows.Forms.SaveFileDialog
$dlg.RestoreDirectory = $true
$dlg.InitialDirectory = "C:\"
$dlg.Filter = "CSV Files (*.csv)|*.csv"
$dlg.Title = "Enter filename to save to"

Write-Output "Please select a directory and enter a filename"

If ($dlg.ShowDialog() -eq 'Ok') {
    $CSVFileName = $dlg.FileName
}
Else {
    Write-Output "Dialog box was closed - please enter a path manually, relative to this location."
    $CSVFileName=Read-Host "Enter the path and filename (WITHOUT a file extension) to export contacts to"
}

Write-Output "Working on it..."
Write-Output "`tThis may take a few minutes, depending on the group size."

$adGroup = Get-ADGroup $GroupName
$memberOf=$adGroup | select -expandproperty distinguishedname

Write-Output ("`tDiscovered group: {0}" -f $adGroup.name)
Write-Output "`tWriting Contacts to $CSVFileName..."

Get-ADObject -Filter 'objectclass -eq "user" -and memberof -eq $memberOf' -properties * | select name,mail,@{e={"$($_.memberOf)"};l="Member Of"} | Export-Csv "$CSVFileName" -NoTypeInformation

Write-Output "`tFinished exporting to $CSVFileName"
Write-Output "`tCreating text file from $CSVFileName..."

Import-Csv "$CSVFileName" | Select-Object -Property mail | foreach {'{0}' -f $_.mail | Out-File -Append ($CSVFileName + "-mail.txt")}

Write-Output "Complete. Please check the output file to verify."
Exit