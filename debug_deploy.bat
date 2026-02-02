@echo off
cd functions
echo Installing dependencies...
call npm install
echo Building project...
call npm run build
echo Deploying with debug logging (saving to deploy_log.txt)...
..\functions\node_modules\.bin\firebase deploy --only functions --debug > ..\deploy_log.txt 2>&1
echo Done! Check deploy_log.txt for errors.
pause
