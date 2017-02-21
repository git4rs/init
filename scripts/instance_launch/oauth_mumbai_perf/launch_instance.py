import yaml
import json
import boto3
import traceback, pdb, sys

hosted_zone_id = "Z2IYTJFY73ZR30"
image_id = "ami-46671129"
key_name = "Oauth-Perf-Devops-Key"
domain = "oauth.perf.local"
instance_details_file = "instance_details.yml"


session = boto3.Session(profile_name='oauth-mumbai-perf')


def set_dns_record(session, hosted_zone_id, domain, ip):
    record_value = {}
    record_value['Value'] = ip
    record = {}
    record['Action'] = "UPSERT"
    record['ResourceRecordSet'] = {}
    record['ResourceRecordSet']['Name'] = domain
    record['ResourceRecordSet']['Type'] = 'A'
    record['ResourceRecordSet']['TTL'] = 60
    record['ResourceRecordSet']['ResourceRecords'] = [record_value]
    client = session.client('route53')
    response = client.change_resource_record_sets(
        HostedZoneId = hosted_zone_id,
        ChangeBatch={
            'Changes': [record]
        })
    print "Response from api: "
    print response

def get_user_data(hostname, ebs_size):
    user_data = "#cloud-config\nhostname: {0}\nfqdn: {0}.oauth.local\n".format(hostname)
    if ebs_size:
        user_data += '\nmounts:\n  - [ "LABEL=drive", "/drive" ]\n'
        user_data += 'fs_setup:\n  - device: /dev/xvdd\n    partition: none\n    label: drive\n    filesystem: ext4'
    return user_data

def launch_instance(session, image_id, instance_type, key_name, subnet_id, hostname, ip, security_groups_id, ebs_size=False):
    client = session.client('ec2')
    user_data = get_user_data(hostname, ebs_size)
    ebs_detail = {}
    ebs_detail['DeviceName'] = "/dev/xvdd"
    ebs_detail['Ebs'] = {}
    ebs_detail['Ebs']['VolumeSize'] = ebs_size
    ebs_detail['Ebs']['DeleteOnTermination'] = False
    ebs_detail['Ebs']['VolumeType'] = 'gp2'
    if ebs_size:
        response = client.run_instances(
            ImageId=image_id,
            KeyName=key_name,
            SecurityGroupIds=security_groups_id,
            UserData=user_data,
            InstanceType=instance_type,
            SubnetId=subnet_id,
            DisableApiTermination=True,
            InstanceInitiatedShutdownBehavior='stop',
            PrivateIpAddress=ip,
            MinCount=1,
            MaxCount=1,
            BlockDeviceMappings=[ebs_detail],
            #EbsOptimized=True
        )
    else:
        response = client.run_instances(
            ImageId=image_id,
            KeyName=key_name,
            SecurityGroupIds=security_groups_id,
            UserData=user_data,
            InstanceType=instance_type,
            SubnetId=subnet_id,
            DisableApiTermination=True,
            InstanceInitiatedShutdownBehavior='stop',
            PrivateIpAddress=ip,
            MinCount=1,
            MaxCount=1,
            #EbsOptimized=True
	)
    instance_id =  response['Instances'][0]["InstanceId"]
    return instance_id

def tag_instance(iid, hostname):
	ec2 = session.client("ec2")
	mytags = [{
	    "Key" : "Name", 
	    "Value" : hostname
	    }]

	ec2.create_tags(
	            Resources = [iid],
	            Tags= mytags
	           )


def main(data):
    for instance in data["instances"]:
        hostname = instance["hostname"]
        ip = instance["ip"]
	fqdn = "{0}.{1}".format(hostname, domain)
        print "Creating DNS record: {0}".format(fqdn)
        set_dns_record(session, hosted_zone_id, fqdn, ip) 
        print "Creating instance: {0}".format(hostname)
	# print instance
	instance_type = instance["instance_type"]
	subnet_id = instance["subnet_id"]
        security_groups_id = instance["security_group_id"]
        if "ebs_size" in instance:
		ebs_size = instance["ebs_size"]
                try:
		    iid = launch_instance(session, image_id, instance_type, key_name, subnet_id, hostname, ip, security_groups_id, ebs_size)
		    print "Instance ID = ", iid
		    tag_instance(iid, hostname)
                except Exception as e:
                    print "1..Exception in hostname: {0}".format(hostname)
		    print str(e)
	else:
            try:
		    iid = launch_instance(session, image_id, instance_type, key_name, subnet_id, hostname, ip, security_groups_id, ebs_size=False)
		    print "Instance ID = ", iid
		    tag_instance(iid, hostname)
            except Exception:
            	    print "Exception in hostname: {0}".format(hostname)



if __name__ == "__main__":
    with open(instance_details_file) as fil:
        data = yaml.load(fil)
        main(data)
