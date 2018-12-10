#!/usr/bin/env python
# Use in CI to list the images in a download repository on OBS
# so we can use the output file to detect a new image available
# and trigger a build.

import argparse
from HTMLParser import HTMLParser
import json
import re
import requests


# HTML Parser
class CIHTMLParser(HTMLParser):
    """ Return the list of available files in the URL """
    files = []

    def handle_starttag(self, tag, attrs):
        if tag == "a":
            for attr in attrs:
                # ('href', 'SUSE-CaaS-Platform-4.0-for-XEN.x86_64.qcow2')
                self.files.append(attr[1])


def parse_args():
    """ Parse command line arguments """
    cli_argparser = argparse.ArgumentParser(description="Process args")
    cli_argparser.add_argument("--url", "-u", required=True, action="store",
                               help="URL of the image download repository")
    cli_argparser.add_argument("--output-file", "-o", required=False,
                               default="files_repo.json", action="store",
                               help="Output file to store the results")
    cli_argparser.add_argument("--insecure", required=False,
                               default=False, action="store_true",
                               help="Ignore TLS validation")

    return cli_argparser.parse_args()


def get_available_files(url, insecure):
    """ Get content of the page """
    try:
        http = requests.Session()
        request = http.get(url, verify=insecure, allow_redirects=True)
        request.raise_for_status()
    except (requests.ConnectionError, requests.HTTPError, requests.Timeout) as e:
        print("connection failed: {0}".format(e))

    # Parse HTML content of the page
    html_parser = CIHTMLParser()
    html_parser.feed(request.content)
    return list(set(html_parser.files))


def filter_results(regex, file_list, ignore_case):
    """ Filter the file list base on regex """
    matched_files = []

    for f in file_list:
        if ignore_case:
            if re.match(regex, f, re.IGNORECASE):
                matched_files.append(f)
        else:
            if re.match(regex, f):
                matched_files.append(f)

    return matched_files


def create_json(url, platforms, file_list):
    """ Create a json with files available per platform """
    json_output = {}
    json_output["url"] = url

    for p in platforms:
        json_output[p] = []

    for f in file_list:
        if re.search("hyperv", f, re.IGNORECASE):
            json_output["hyperv"].append(f)

        if re.search("kvm", f, re.IGNORECASE):
            json_output["kvm"].append(f)

        if re.search("openstack", f, re.IGNORECASE):
            json_output["openstack"].append(f)

        if re.search("vmware", f, re.IGNORECASE):
            json_output["vmware"].append(f)

        if re.search("xen", f, re.IGNORECASE):
            if not re.search("kvm", f, re.IGNORECASE):
                json_output["xen"].append(f)

    return json.dumps(json_output, indent=2, sort_keys=True)


def write_file(path, content):
    """ Write content into a file """
    try:
        with open(path, "w") as f:
            f.write(content)
        print("File successfully created: {0}".format(path))
    except IOError as e:
        print("i/o error: {0}".format(e))


def main():
    args = parse_args()
    url = args.url
    output_file = args.output_file
    insecure = args.insecure

    results = get_available_files(url, insecure)
    results = filter_results("^SUSE|^SLE", results, ignore_case=True)

    platforms = ["hyperv", "kvm", "openstack", "vmware", "xen"]
    json_output = create_json(url, platforms, results)

    print(json_output)
    write_file(output_file, json_output)


if __name__ == "__main__":
    main()
