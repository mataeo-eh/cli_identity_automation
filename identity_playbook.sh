# Log into azure cli using az login and following the prompt that appears
# Once logged in, select the subscription to log into, for this case [1] the student subscription
# az account list -o table will show which subscriptions are available for your account
    # The generated table also shows which subscription is the default in the IsDefault column
    # My student subscription is the defualt subscription, and the only one available to me
# I used the CLI identifier to get the signed in user information and an API call to retrieve
# the list of groups I am in in order to use both the baked in CLI identifiers and an API call. 

# Begin the script below
#!/bin/bash
echo "set environment to bash"

set -e # Exit script if a command fails

# Sets a timestamp environment variable that calls the system date function and returns it
# in a format compatible with azure naming (excludes white space and colons)
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)

# Saves the name for the log file as an environment variable for easy reference
LOGFILE="identity_log.txt"

# Shows information about the signed in user and saves the raw data in json format to me.json
az ad signed-in-user show -o json > me.json 

# Shows the groups the signed in user is a member of and saves the raw data in json format to my_groups.json
az rest --method get --uri https://graph.microsoft.com/v1.0/me/memberOf -o json > my_groups.json

# -----------------------------------------------------------------------------------------------------------
#                            Process Automation Assignment Script Description
# -----------------------------------------------------------------------------------------------------------
# name: Mataeo Anderson
# date: Wednesday November 19th 2025

# This script assumes the user has logged in through the azure CLI following the instructions 
# in the comments at the top of the script. It then fetches information about the user
# and saves the raw data to me.json. It will then fetch the groups the user is currently in
# and saves those to my_groups.json. It will then create a new group, add the user to it, remove all
# members from the group, and delete the created group for full cleanup.
#
# one sentence description: This script uses the azure CLI and microsoft graph API calls to fetch user 
# information, create an AD group, add the user to the group, and then removes the group for cleanup.
# -----------------------------------------------------------------------------------------------------------

echo "Getting signed-in user UPN..."
# Saves environment variable for the UPN of the signed in user
USER_UPN=$(az ad signed-in-user show --query userPrincipalName -o tsv)
# Saves environment variable for the first and last name of the signed in user
USER_NAME=$(az ad signed-in-user show --query "join(' ', [givenName, surname])" -o tsv)
echo "Signed-in UPN: $USER_UPN"
echo "Getting user object ID..."
# Saves environment variable for the ID of the signed in user
USER_ID=$(az ad user show --id "$USER_UPN" --query id -o tsv)
echo "User Object ID: $USER_ID"
# Saves an environment variable for the name of the AD group to be created
GROUP_NAME="ProcessAutomationLab$TIMESTAMP"
# Saves an environment variable for the mail nickname of the group to be created
GROUP_NICK="ProcessAutomationLabNick$TIMESTAMP"

echo "Creating Azure AD security group '$GROUP_NAME'..."
# Creates the group with the pre-defined group name and uses --query to save the id of the created group 
# to the GROUP_ID environment variable
GROUP_ID=$(az ad group create \
  --display-name "$GROUP_NAME" \
  --mail-nickname "$GROUP_NICK" \
  --query id -o tsv)
echo "Group $GROUP_NAME created with ID: $GROUP_ID"

# Saves the created message prefixed with the current date and appends it to identity_log.txt
# or creates it if it does not yet exist. 
echo "$(date) Group $GROUP_NAME created with ID: $GROUP_ID" >> $LOGFILE

# Adds the user to the previously created group using the saved USER_ID environment variable
echo "Adding user to group..."
az ad group member add --group "$GROUP_NAME" --member-id "$USER_ID"
echo "User added to $GROUP_NAME group."
# Adds to the log file that the user was added to the group
echo "User $USER_NAME was added to group $GROUP_NAME" >> $LOGFILE

echo "Listing members of $GROUP_NAME group..."
# Lists the members of the created group to verify the user was added - uses the azure CLI
az ad group member list --group "$GROUP_NAME" --output table
echo "Listing members of the group $GROUP_NAME using rest API call"
# Uses the microsoft graph API to list the members of the created group to show two separate methods
# of verifying the user was added to the created group
az rest --method get \
  --uri "https://graph.microsoft.com/v1.0/groups/$GROUP_ID/members"
# Parses the list to check for the user UPN in the group.
# It returns a boolean which is stored as an environment variable
IN_GROUP=$(az ad group member list --group "$GROUP_NAME" \
  --query "contains([].id, '$USER_ID')" \
  -o tsv)
# Appends the resulting boolean to the log file
echo "$USER_NAME in $GROUP_NAME : $IN_GROUP"
echo "$USER_NAME in $GROUP_NAME : $IN_GROUP" >> "$LOGFILE"


echo ""
# Adds an interactive prompt to confirm the user wants to remove members from the group and delete it
read -p "Do you want to remove ALL members and delete the group '$GROUP_NAME'? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" && "$CONFIRM" != "yes" && "$CONFIRM" != "Yes" && "$CONFIRM" != "YES" ]]; then
    echo "Operation cancelled. Group and members were NOT modified."
    exit 0
fi
echo "Confirmed. Proceeding with group cleanup."
echo "User confirmed to proceed with group cleanup. Removing all members and deleting group." >> "$LOGFILE"
# Gets all the member IDs for every member in the group and removes them each from it
for MEMBER_ID in $(az ad group member list \
    --group "$GROUP_NAME" \
    --query "[].id" -o tsv); do

    echo "Removing member: $MEMBER_ID"
    echo "Removing member: $MEMBER_ID" >> "$LOGFILE"
    az ad group member remove \
        --group "$GROUP_NAME" \
        --member-id "$MEMBER_ID"
done
echo "All members removed."
echo "All members removed." >> "$LOGFILE"
echo "Deleting group $GROUP_NAME"
# Deletes the created group
az ad group delete --group "$GROUP_NAME"
echo "group $GROUP_NAME deleted"
echo "group $GROUP_NAME deleted" >> "$LOGFILE"
echo "Script completed successfully at $(date)"
echo "Script completed successfully at $(date)" >> "$LOGFILE"
