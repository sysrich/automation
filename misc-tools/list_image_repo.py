#!/usr/bin/env python
# Use in CI to list the images in a download repository on OBS
# so we can use the output file to detect a new image available
# and trigger a build.

import argparse
from html.parser import HTMLParser
import json
import os
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
                               help="url of the image download repository")
    cli_argparser.add_argument("--result-file", "-o", required=False,
                               default="files_repo.json", action="store",
                               help="output file to store the results")
    cli_argparser.add_argument("--download-checksum", "-dc", required=False,
                               action="store_true",
                               help="download sha256 checksum files")
    cli_argparser.add_argument("--checksum-dir", "-d", required=False,
                               default="./", action="store",
                               help="output directory to store the sha256 checksum files")
    cli_argparser.add_argument("--insecure", required=False,
                               default=False, action="store_true",
                               help="ignore TLS validation")

    return cli_argparser.parse_args()


def http_get(url, insecure):
    """ Get content of an URL """
    try:
        http = requests.Session()
        request = http.get(url, verify=insecure, allow_redirects=True)
        request.raise_for_status()
    except (requests.ConnectionError, requests.HTTPError, requests.Timeout) as e:
        print("connection failed: {0}".format(e))

    return request.text


def parse_html(html_content):
    """ Parse HTML content of the page """
    html_parser = CIHTMLParser()
    html_parser.feed(html_content)
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
        with open(path, "w", encoding="utf-8") as f:
            f.write(content)
        print("INFO: File successfully created: {0}\n".format(path))
    except IOError as e:
        print("i/o error: {0}".format(e))


def main():
    args = parse_args()
    result_file = args.result_file
    download_checksum = args.download_checksum
    checksum_dir = args.checksum_dir
    insecure = args.insecure
    url = args.url

    if url[-1] is not "/":
        url = "{0}/".format(url)

    if checksum_dir[-1] is not "/":
        checksum_dir = "{0}/".format(checksum_dir)

    print("INFO: Searching {0}".format(url))
    html_page = http_get(url, insecure)
    results = parse_html(html_page)
    results = filter_results("^SUSE|^SLE", results, ignore_case=True)
    sha256files = filter_results(".*sha256$", results, ignore_case=False)

    platforms = ["hyperv", "kvm", "openstack", "vmware", "xen"]
    json_output = create_json(url, platforms, results)

    print("INFO: Available files:")
    print(json_output)
    write_file(result_file, json_output)

    if download_checksum:
        print("INFO: Retrieving sha256 checkfum files\n")
        if not os.path.exists(checksum_dir):
            os.makedirs(checksum_dir)

        for f in sha256files:
            link = "{0}{1}".format(url, f)
            print("INFO: {0}:".format(f))
            sha256 = http_get(link, insecure)
            print(sha256, end="")
            write_file("{0}{1}".format(checksum_dir, f), sha256)

    print("INFO: Done")

if __name__ == "__main__":
    main()
