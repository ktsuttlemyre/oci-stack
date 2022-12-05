#!/bin/bash
connect () {
        ssh ubuntu@"$(<~/instances/$INSTANCE)" -i ~/.ssh/ktsuttlemyre
        return $?
}

TMP_FILE=$(mktemp)
query () {
    #get stack id
    #oci resource-manager stack list --sort-by TIMECREATED --sort-order DESC --lifecycle-state ACTIVE &
    STACK_ID="ocid1.ormstack.oc1.iad.amaaaaaauw7u7haataho2v7nqyp3qexct34h3kg335u6xl5jta6pyl4buoka"

    # get data
    oci resource-manager stack get-stack-tf-state --file - --stack-id "$STACK_ID" > "$TMP_FILE" &
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


mkdir -p ~/instances
INSTANCE="${1:-ampere}"
query

if ! connect; then
    echo "SSH connection failed. Waiting for ip query"
    query_wait
    echo "trying connection again"
    connect
fi
