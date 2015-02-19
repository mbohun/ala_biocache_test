#!/usr/bin/env python

import sys
import argparse
import json
from jsonpath_rw import jsonpath, parse

def extract(json_data, json_path):
    jsonpath_expr = parse(json_path)
    for item in [match.value for match in jsonpath_expr.find(json_data)]:
        print item

if __name__=="__main__":
    # TODO: add arg-s processing as we go and need them
    parser = argparse.ArgumentParser(description='diff simple utils to extract/process info from biocache JSON results/messages.')
    parser.add_argument('-j', '--json-path', type=str, dest='json_path', help='JSONPath expression')
    args = parser.parse_args()

    sin = sys.stdin.read()

    json_data = json.loads(sin)
    extract(json_data, args.json_path)

