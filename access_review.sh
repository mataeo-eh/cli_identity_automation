#  az rest --method get --uri "https://graph.microsoft.com/v1.0/me/memberOf?\$select=displayName,id" -o json > graph_memberOf.json
#  Command run to generate json file listing groups I am in as the signed in user

# Sets a timestamp environment variable that calls the system date function and returns it
# in a format compatible with azure naming (excludes white space and colons)
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
# Turns each entry in the JSON file into a one line json for extracting information
jq -c '.value[]' my_groups.json | while read -r group; do
    # Extracts the display name, and id of each entry. Normalizes the display name as lowercase for rule checks
    NAME=$(echo "$group" | jq -r '.displayName')
    ID=$(echo "$group" | jq -r '.id')
    NAME_LOWER=${NAME,,}
    echo "Checking: $NAME ($ID)"
    # Creates access_report.txt if it does not exist. appends a timestamp and the group name 
    # and group id of each group the user is in
    #echo "$TIMESTAMP Checking: $NAME ($ID)" >> access_report.txt
    # Checks if the normalized name contains student in it using REGEX pattern matching
    if [[ "$NAME_LOWER" =~ student ]]; then
        echo "The group $NAME is for students."
        # Appends the result of the rule check to the 'log' file 
        #echo "$TIMESTAMP The group $NAME is for students." >> access_report.txt
        #echo "$TIMESTAMP Rule check: COMPlIANT" >> access_report.txt
        echo "$TIMESTAMP : $NAME , $ID , COMPLIANT" >> access_report.txt
    else
        echo "The group $NAME is not for students."
        # Appends result of check to the 'log' file 
        #echo "The group $NAME is not for students." >> access_report.txt
        #echo "$TIMESTAMP Rule check: NON-COMPLIANT" >> access_report.txt
        echo "$TIMESTAMP : $NAME , $ID , NON-COMPLIANT" >> access_report.txt
    fi
done
