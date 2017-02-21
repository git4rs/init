#!/usr/bin/env python
import boto3

iid="i-02a489c49913e02fc"

session = boto3.Session(profile_name='oauth-mumbai-perf')

ec2 = session.client("ec2")
mytags = [{
    "Key" : "Name", 
    "Value" : "perf-ntp-0-132"
    }]


ec2.create_tags(
            Resources = [iid],
            Tags= mytags
           )
