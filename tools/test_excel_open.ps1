param (
    [string]$FilePath
)

$absPath = (Resolve-Path $FilePath).Path
Write-Host "=================================================="
Write-Host "TESTING WITH REAL MS EXCEL: $absPath"
Write-Host "=================================================="

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false

$tempDir = [System.IO.Path]::GetTempPath()
$beforeFiles = Get-ChildItem -Path $tempDir -Include "*.xml" -Recurse | Select-Object -ExpandProperty FullName

try {
    $wb = $excel.Workbooks.Open($absPath, 0, $true)
    Write-Host "STATUS: SUCCESS_OPEN"
    Write-Host "Sheet count:" $wb.Sheets.Count
    $wb.Close($false)
} catch {
    Write-Host "STATUS: EXCEL_REPAIR_OR_FAILED"
    Write-Host "Error message:" $_.Exception.Message
} finally {
    $excel.Quit()
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
}
