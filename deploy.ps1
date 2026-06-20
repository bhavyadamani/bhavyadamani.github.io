$git = "C:\Program Files\Git\cmd\git.exe"

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "  Bhavya Damani - Portfolio Deployer" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

Set-Location "d:\Projects\portflio-v2"

Write-Host "`n[1/4] Checking status..." -ForegroundColor Yellow
& $git status

Write-Host "`n[2/4] Staging all changes..." -ForegroundColor Yellow
& $git add -A

Write-Host "`n[3/4] Committing..." -ForegroundColor Yellow
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
& $git commit -m "Deploy: Portfolio update - $timestamp"

Write-Host "`n[4/4] Pushing to GitHub..." -ForegroundColor Yellow
& $git push origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ SUCCESS! Your site will be live at https://bhavyadamani.github.io/ in ~1 minute." -ForegroundColor Green
} else {
    Write-Host "`n❌ Push failed. See error above." -ForegroundColor Red
}

Write-Host "`nPress any key to close..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
