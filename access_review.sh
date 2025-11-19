#  az rest --method get --uri "https://graph.microsoft.com/v1.0/me/memberOf?\$select=displayName,id" -o json > graph_memberOf.json
#  Command run to generate json file listing groups I am in as the signed in user


jq -c '.value[]' my_groups.json | while read -r group; do
    NAME=$(echo "$group" | jq -r '.displayName')
    ID=$(echo "$group" | jq -r '.id')
    NAME_LOWER=${name,,}
    echo "Checking: $NAME ($ID)"
    echo "Checking: $NAME ($ID)" >> access_report.txt

    if [[ "$NAME_LOWER" =~ "student" ]]; then
        echo "The group $NAME is for students."
    fi
done
