#!/bin/bash

whiptail --title "GVM Reporting Fix" --msgbox "This tool was created as a short term solution to fix the issue with reporting. Currently, you are only able to export 1000 lines in any of the reports. This tool will help fix that problem, but creates another problem at the same time. If you haven't already, please read the specific details on our github" 15 60

# patching functions
exportingPatch(){
gvmd --modify-setting 76374a7a-0569-11e6-b6da-28d24461215b             --value 100000
}
webUIPatch(){
gvmd --modify-setting 76374a7a-0569-11e6-b6da-28d24461215b             --value 100
}

fixMenu=$(
whiptail --title "GVM Reporting Fix" --menu "Please select an option:" 15 75 3 \
        '1)' "Exporting Patch - Export more than 1000 lines in reports" \
        '2)' "WebUI Patch - Be able to view report data in the web interface" \
        'X)' "exit" 3>&2 2>&1 1>&3
)

case $fixMenu in
        "1)")
                exportingPatch
                ;;
        "2)")
                webUIPatch
                ;;
        "X)")
                exit
                ;;
esac

