#!/bin/bash
# original source
# https://blogs.oracle.com/cloud-infrastructure/post/customize-block-volume-backups-with-the-oracle-cloud-infrastructure-cli

#Customized Volume Backup Script
#Before you can run this customized script, you need to install the CLI on your compute instance. Detailed instructions for installing the CLI are located in the documentation.

#Step 1
#The first step of this script gets required information about where this compute instance is located, such as availability domain, compartment OCID, and instance OCID. You can get this information through the metadata of the compute instance.
OCI_CLI_AUTH=instance_principal

# Get availability domain
AD=$(curl -s http://169.254.169.254/opc/v1/instance/ | jq -r '.availabilityDomain' )
echo "AD=$AD"

# Get Compartment-id
COMPARTMENT_ID=$(curl -s http://169.254.169.254/opc/v1/instance/ | jq -r '.compartmentId' )
echo "COMPARTMENT_ID=$COMPARTMENT_ID"

# Get Instance-id
INSTANCE_ID=$(curl -s http://169.254.169.254/opc/v1/instance/ | jq -r '.id' )
echo "INSTANCE_ID=$INSTANCE_ID"

 

#Step 2
#The second step of the script gets the tagging information from the boot volume of the compute instance. Then you can use the same tagging information to create the volume group and its backups. With the same tags, you can easily to sort or filter your volumes and their backups.     
# Get tags of boot volume of this instance\
# We will use these tags for volume group created for this instance's boot volume and other attached volumes

# Get boot Volume tag
BOOTVOLUME_DEFINED_TAGS=$(oci compute boot-volume-attachment list --compartment-id=$COMPARTMENT_ID --availability-domain=$AD --instance-id=$INSTANCE_ID | jq -r '.data[] | ."defined-tags" // {}')
echo "BOOTVOLUME_DEFINED_TAGS=$BOOTVOLUME_DEFINED_TAGS"
BOOTVOLUME_FREEFORM_TAGS=$(oci compute boot-volume-attachment list --compartment-id=$COMPARTMENT_ID --availability-domain=$AD --instance-id=$INSTANCE_ID | jq -r '.data[] | ."freeform-tags" // {}')
echo "BOOTVOLUME_FREEFORM_TAGS=$BOOTVOLUME_FREEFORM_TAGS"
# Note: The jq command is very useful for parsing the JSON output from the CLI. 


# Step 3
# The third step of the script gets the boot volume OCID and a list of attached block volumes' OCIDs for the compute instance. These OCIDs will be used to construct JSON data for the volume group creation command. 
# Get boot volume-id
BOOTVOLUME_ID=$(oci compute boot-volume-attachment list --compartment-id=$COMPARTMENT_ID --availability-domain=$AD --instance-id=$INSTANCE_ID | jq -r '.data[]."boot-volume-id"')
echo "BOOTVOLUME_ID=$BOOTVOLUME_ID"


# Get a list of attached block volumes
BLOCKVOLUME_LIST=($(oci compute volume-attachment list --compartment-id=$COMPARTMENT_ID --availability-domain=$AD --instance-id=$INSTANCE_ID | jq -r '.data[]."volume-id"'))

# Construct JSON for volume group creat command
LIST="[\"$BOOTVOLUME_ID\""
for volume in ${BLOCKVOLUME_LIST[*]}; do
   LIST="${LIST}, \"${volume}\""
done
LIST="${LIST}]"
SOURCE_DETAILS_JSON="{\"type\": \"volumeIds\", \"volumeIds\": $LIST}"
echo "SOURCE_DETAILS_JSON=$SOURCE_DETAILS_JSON"
#Example:
#[
#  "This parameter should actually be a JSON object rather than an array - pick one of the following object variants to use",
#  {
#    "type": "volumeGroupBackupId",
#    "volumeGroupBackupId": "string"
#  },
#  {
#    "type": "volumeGroupId",
#    "volumeGroupId": "string"
#  },
#  {
#    "type": "volumeGroupReplicaId",
#    "volumeGroupReplicaId": "string"
#  },
#  {
#    "type": "volumeIds",
#    "volumeIds": [
#      "string",
#      "string"
#    ]
#  }
#]





# Step 4
# The fourth step of the script checks whether existing volume groups have been created by the script before.

# If there is no existing volume group, the script creates the volume group based on the information from the previous steps, such as list OCIDs of the boot volume and all the attached block volumes.
# If there is an existing volume group, the script checks whether there are any changes to the member volumes inside the volume group; for example, new block volumes are attached to the compute instance. If there are changes, the script updates the volume group with the latest volumes. 
# Check whether there is an existing available volume group created by the script.

VOLUME_GROUP_NAME="volume-group-$INSTANCE_ID"
echo "VOLUME_GROUP_NAME=$VOLUME_GROUP_NAME"

VOLUME_GROUP_ID=$(oci bv volume-group list --compartment-id $COMPARTMENT_ID --availability-domain $AD --display-name $VOLUME_GROUP_NAME | jq -r '.data[] | select(."lifecycle-state" == "AVAILABLE") | .id')
# If volume group does not exist, then create a new volume group
if [ -z "$VOLUME_GROUP_ID" ]; then
    echo "VOLUME_GROUP_ID was not set so we are creating one"
    # Create volume group
    VOLUME_GROUP_ID=$(oci bv volume-group create --compartment-id $COMPARTMENT_ID --availability-domain $AD --source-details "$SOURCE_DETAILS_JSON" --defined-tags="$BOOTVOLUME_DEFINED_TAGS" --freeform-tags="$BOOTVOLUME_FREEFORM_TAGS" --display-name=$VOLUME_GROUP_NAME --wait-for-state AVAILABLE --max-wait-seconds 24000 | jq -r '.data.id' )
    echo "VOLUME_GROUP_ID=$VOLUME_GROUP_ID"
    # add base_save tag
    BOOTVOLUME_FREEFORM_TAGS=$(echo "$BOOTVOLUME_FREEFORM_TAGS" | jq -r --arg init true '. + {init: $init}')
    echo "UPDATED BOOTVOLUME_FREEFORM_TAGS = $BOOTVOLUME_FREEFORM_TAGS"
else
    echo "VOLUME_GROUP_ID=$VOLUME_GROUP_ID"
    # volume group exists and then check whehter there are any changes for the attached block volumes
    VOLUME_LIST_IN_VOLUME_GROUP=$(oci bv volume-group get --volume-group-id $VOLUME_GROUP_ID | jq -r '.data | ."volume-ids"' | grep ocid1.volume )

    # compare with attached block volume list
    LIST3=$(echo $BLOCKVOLUME_LIST $VOLUME_LIST_IN_VOLUME_GROUP | tr ' ' '\n' | sort | uniq -u)
    if [ -z "$LIST3" ]; then
        echo "no change for volume group"
    else
        # update volume group with updated volume ids list
        VOLUME_GROUP_ID=$(oci bv volume-group update --volume-group-id $VOLUME_GROUP_ID --volume-ids "$LIST" --defined-tags="$BOOTVOLUME_DEFINED_TAGS" --freeform-tags="$BOOTVOLUME_FREEFORM_TAGS" --display-name=$VOLUME_GROUP_NAME --wait-for-state AVAILABLE --max-wait-seconds 24000 | jq -r '.data[].id')
    fi
fi


# Step 5
# The last step of the script creates the backup for this volume group. The script uses the same tags, defined-tags and freeform-tags, from the boot volume of the compute instance. However, you can define your own customized tags as needed. 

# Create Backup
VOLUME_GROUP_BACKUP_NAME="Volume-group-backup-$VOLUME_GROUP_ID"
echo "VOLUME_GROUP_BACKUP_NAME=$VOLUME_GROUP_BACKUP_NAME"

VOLUME_GROUP_BACKUP_ID=$(oci bv volume-group-backup create --volume-group-id $VOLUME_GROUP_ID --defined-tags="$BOOTVOLUME_DEFINED_TAGS" --freeform-tags="$BOOTVOLUME_FREEFORM_TAGS" --display-name=$VOLUME_GROUP_BACKUP_NAME --wait-for-state AVAILABLE --max-wait-seconds 24000) # | grep ocid1.volumegroupbackup | awk '{print $2;}' |awk -F\" '{print $2;}')
echo "VOLUME_GROUP_BACKUP_ID=$VOLUME_GROUP_BACKUP_ID"
# You can configure the cron job to run this customized volume backup script according to your backup schedule. 



# Volume Backup Retention Script
# Based on your requirements, you might need to define a customized and flexible retention period for your volume backups. For example, say you want the retention period of the volume backups to be 14 days.  Following example script checks the creation times for your volume backups and then deletes the old backups beyond the retention period. You can configure and run this script in your cron job based on how often you want to conduct a backup retention check. 
RETENTION_DAYS=14 #this is hardcoded below. this value does nothing

# get all the volume group backup
VOLUME_GROUP_BACKUP_LIST=$(oci bv volume-group-backup list --compartment-id $COMPARTMENT_ID --volume-group-id $VOLUME_GROUP_ID --display-name=$VOLUME_GROUP_BACKUP_NAME | jq -r '.data[] | select(."freeform-tags" | has("init") | not) | select (."time-created" | sub("\\.[0-9]+[+][0-9]+[:][0-9]+$"; "Z") | def daysAgo(days):  (now | floor) - (days * 86400); fromdateiso8601 < daysAgo(14)) | .id')

echo $VOLUME_GROUP_BACKUP_LIST
for backup in ${VOLUME_GROUP_BACKUP_LIST[*]}; do
   DELETED_VOLUME_GROUP_BACKUP_ID=$(oci bv volume-group-backup delete --volume-group-backup-id ${backup} --force --wait-for-state TERMINATED --max-wait-seconds 24000)
   echo "DELETED: $DELETED_VOLUME_GROUP_BACKUP_ID"
done
