#!/bin/bash
connect () {
        key="$HOME/.ssh/$(whoami)"
        if [ ! -f "$key" ]; then
                echo "Need to add a ssh key to $key"
                return 1
        fi
        ssh -o ConnectTimeout=10 ubuntu@"$(<~/instances/$INSTANCE)" -i "$key"
        return $?
}

TMP_FILE=$(mktemp)
query () {
    #get tenancy id 
    # https://www.dbarj.com.br/en/2020/10/get-your-tenancy-ocid-using-a-single-oci-cli-command/
    TENANCY_ID=$(oci iam compartment list --all --compartment-id-in-subtree true --access-level ACCESSIBLE --include-root --raw-output --query "data[?contains(\"id\",'tenancy')].id | [0]")
    #get stack id
    STACK_ID=$(oci resource-manager stack list --compartment-id "$TENANCY_ID" --sort-by TIMECREATED --sort-order DESC --lifecycle-state ACTIVE --raw-output  --query "data [0].id")
    # get data
    oci resource-manager stack get-stack-tf-state --file - --stack-id "$STACK_ID" > "$TMP_FILE"
}

query_wait (){
    FAIL=0

    for job in `jobs -p`; do
    echo $job
        wait $job || let "FAIL+=1"
    done

    if [ "$FAIL" != "0" ]; then
        echo "Several ip query's failed: number failed = ($FAIL)"
    else
        #extract ips
        # get ampere ip
        cat $TMP_FILE | jq ".resources" | grep "ip_address" | cut -d '"' -f 4 | tail -1 > ~/instances/ampere
        #get mini ip
        cat $TMP_FILE | jq -r '.resources[] | select(.type == "oci_core_instance") | .instances[] | select(.attributes.create_vnic_details[].hostname_label == "mini-1") | .attributes.public_ip' > ~/instances/mini-1
        #get mini 2 ip
        cat $TMP_FILE | jq -r '.resources[] | select(.type == "oci_core_instance") | .instances[] | select(.attributes.create_vnic_details[].hostname_label == "mini-2") | .attributes.public_ip' > ~/instances/mini-2
    fi
    return $FAIL
}

update_self (){
        file="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")" # get my script name
        # -z will make curl only download if it's changed
        curl -L "https://raw.githubusercontent.com/ktsuttlemyre/rogue-stack/main/cloudshell/$file" -s --output "$file" --silent -z "$file"
        return $?
}

mkdir -p ~/instances
INSTANCE="${1:-ampere}"
query &
update_self &
connect
#exit_code 130 is a successful exit from terminal
#so dont treat it as an error and reconnect
if [ $? -ne 0 ] || [ $? -ne 130 ]; then
    echo "SSH connection failed. Waiting for ip query"
    query_wait
    echo "trying connection again"
    connect
fi
