#!/usr/bin/env python

import sys
import argparse
import json



def extract_facetResults(json_data, field_name):
    KEY = "facetResults" 

    if KEY in json_data:
        for facet in json_data[KEY]:
            print '{}'.format(facet[field_name])

    else:
        print 'key "{}" not found'.format(KEY)

# TODO: either setup a jump table; or use JSONpath expression-s
def extract(json_data, field_name):
    return extract_facetResults(json_data, field_name)

if __name__=="__main__":
    # TODO: add arg-s processing as we go and need them
    parser = argparse.ArgumentParser(description='diff simple utils to extract/process info from biocache JSON results/messages.')
    parser.add_argument('-f', '--extract-field', type=str, dest='field_name', help='Extract field value-s from a JSON string.')
    args = parser.parse_args()
    print args.field_name

    sin = sys.stdin.read()

    json_data = json.loads(sin)
    extract_facetResults(json_data, args.field_name)
