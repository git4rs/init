# -*- coding: utf-8 -*-
##########################################################################
# Copyright 2013-2016 Aerospike, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##########################################################################

from __future__ import print_function

import aerospike
import sys

from optparse import OptionParser

##########################################################################
# Options Parsing
##########################################################################

usage = "usage: %prog [options]"

optparser = OptionParser(usage=usage, add_help_option=False)

optparser.add_option(
    "--help", dest="help", action="store_true",
    help="Displays this message.")

optparser.add_option(
    "-n", "--namespace", dest="ns", type="string", default="test", metavar="<ADDRESS>",
    help="Namespace for backup.")

optparser.add_option(
    "-s", "--set", dest="setname", type="string", default="demo", metavar="<ADDRESS>",
    help="Set for backup.")

optparser.add_option(
    "-h", "--source-host", dest="shost", type="string", default="127.0.0.1", metavar="<ADDRESS>",
    help="Address of Aerospike destination server.")

optparser.add_option(
    "-p", "--source-port", dest="sport", type="int", default=3000, metavar="<PORT>",
    help="Port of the Aerospike source server.")

optparser.add_option(
    "-y", "--dest-host", dest="dhost", type="string", default="127.0.0.1", metavar="<ADDRESS>",
    help="Address of Aerospike destination server.")

optparser.add_option(
    "-z", "--dest-port", dest="dport", type="int", default=3000, metavar="<PORT>",
    help="Port of the Aerospike destination server.")

optparser.add_option(
    "-d", "--digest-file", dest="digfile", type="string", default="dig", metavar="<PORT>",
    help="Digest File Location.")

optparser.add_option(
    "-b", "--large-bin", dest="largebin", type="string", default="lbin", metavar="<PORT>",
    help="Digest File Location.")


(options, args) = optparser.parse_args()

if options.help:
    optparser.print_help()
    print()
    sys.exit(1)

##########################################################################
# Client Configuration
##########################################################################

src_config = {
    'hosts': [(options.shost, options.sport)]
}

dest_config = {
    'hosts': [(options.dhost, options.dport)]
}

##########################################################################
# Application
##########################################################################

exitCode = 0

try:

    # ----------------------------------------------------------------------------
    # Connect to Both Clusters
    # ----------------------------------------------------------------------------

    src_client = aerospike.client(src_config).connect()
    dest_client = aerospike.client(dest_config).connect()

    # ----------------------------------------------------------------------------
    # Perform Operations
    # ----------------------------------------------------------------------------
    try:
        policy = {}

        with open(options.digfile) as ifile:

            for d in ifile:
                key = (options.ns, options.setname, None, bytearray(d[:20])) 

                readList = src_client.apply(key, "llist", "scan", [options.largebin], policy=policy)

                dest_client.apply(key, "llist", "update", [options.largebin, readList], policy=policy)

                print ("Stuff")

    except Exception as e:
        print("error: {0}".format(e), file=sys.stderr)
        exitCode = 2

    # ----------------------------------------------------------------------------
    # Close Connection to Cluster
    # ----------------------------------------------------------------------------

    src_client.close()
    dest_client.close()

except Exception as eargs:
    print("error: {0}".format(eargs), file=sys.stderr)
    exitCode = 3

##########################################################################
# Exit
##########################################################################

sys.exit(exitCode)
