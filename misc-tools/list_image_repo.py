#!/usr/bin/env python3
# Use in CI to list the images in a download repository on OBS
# so we can use the output file to detect a new image available
# and trigger a build.

import argparse
from collections import defaultdict
from html.parser import HTMLParser
import json
import os
import re
import requests
import sys


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
    cli_argparser.add_argument("--download-checksum", "-d", required=False,
                               action="store_true",
                               help="download sha256 checksum files")
    cli_argparser.add_argument("--checksum-dir", "-c", required=False,
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
        sys.exit("connection failed: {0}".format(e))

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


def create_json(url, platforms_regex, file_list):
    """ Create a json with files available per platform """
    json_output = defaultdict(list)
    json_output["url"] = url

    for f in file_list:
        platform = re.search(platforms_regex, f, re.IGNORECASE)
        if platform is not None:
            json_output[platform.group(0).lower()].append(f)

    return json.dumps(json_output, indent=2, sort_keys=True)


def write_file(path, content):
    """ Write content into a file """
    try:
        with open(path, "w", encoding="utf-8") as f:
            f.write(content)
        print("INFO: file successfully created: {0}\n".format(path))
    except IOError as e:
        sys.exit("i/o error: {0}".format(e))


def main():
    args = parse_args()
    result_file = args.result_file
    download_checksum = args.download_checksum
    checksum_dir = args.checksum_dir
    insecure = args.insecure
    url = args.url

    if not url.endswith("/"):
        url = url + "/"

    print("INFO: Searching {0}".format(url))
    html_page = http_get(url, insecure)
    results = parse_html(html_page)
    results = filter_results("^SUSE|^SLE", results, ignore_case=True)
    sha256files = filter_results(".*sha256$", results, ignore_case=False)

    platforms_regex = "kvm|hyperv|openstack|vmware|(?<!kvm-and-)xen"
    json_output = create_json(url, platforms_regex, results)

    print("INFO: Available files:")
    print(json_output)
    write_file(result_file, json_output)

    if download_checksum:
        print("INFO: Retrieving sha256 checkfum files\n")
        if not os.path.exists(checksum_dir):
            os.makedirs(checksum_dir)

        for f in sha256files:
            link = url + f
            print("INFO: {0}:".format(f))
            sha256 = http_get(link, insecure)
            print(sha256, end="")
            write_file(os.path.join(checksum_dir, f), sha256)

    print("INFO: Done")

if __name__ == "__main__":
    main()
