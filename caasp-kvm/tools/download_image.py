#!/usr/bin/env python
try:
    import requests
except ImportError:
    print("Please install python-requests")
    raise SystemExit(1)
import argparse
import urlparse
import os
import re
from HTMLParser import HTMLParser


class ImageFinder(HTMLParser):

    def __init__(self, docker_image_name):
        HTMLParser.__init__(self)
        self.images = set()

        if docker_image_name:
            self.regexp = '{}.*x86_64-.*\.tar\.xz'.format(docker_image_name)
        else:
            self.regexp = '.*KVM.*x86_64-.*\.qcow2'

    def get_image(self):
        return self.images.pop()

    def handle_data(self, data):
        m = re.search(self.regexp, data)
        if m:
            self.images.add(m.group(0))


def get_versioned_image_link(url):
    image = requests.head(url)
    
    if image.status_code == 302 or image.status_code == 301:
        return get_versioned_image_link(image.headers.get('Location'))
    elif image.status_code == 200:
        return url
    else:
        raise Exception("Cannot find image location")


def get_filename(url):
    return urlparse.urlparse(url).path.split('/')[-1]


def get_channel_url(url, docker_image_name):

    channel = urlparse.urlparse(url).netloc

    parser = ImageFinder(docker_image_name)

    url_base = {
        'release': 'http://download.suse.de/ibs/SUSE:/SLE-12-SP2:/Update:/Products:/CASP10/',
        'staging_a': 'http://download.suse.de/ibs/SUSE:/SLE-12-SP2:/Update:/Products:/CASP10:/Staging:/A/',
        'staging_b': 'http://download.suse.de/ibs/SUSE:/SLE-12-SP2:/Update:/Products:/CASP10:/Staging:/B/',
        'devel': 'http://download.suse.de/ibs/Devel:/CASP:/1.0:/ControllerNode/',
        'head': 'http://download.suse.de/ibs/Devel:/CASP:/1.0:/ControllerNode/',
    }

    if channel not in url_base:
        raise Exception("Unknown channel: %s" % channel)

    base_url = url_base[channel]
    if docker_image_name:
        base_url += 'images_container_derived'
    else:
        base_url += 'images'

    r = requests.get(base_url)
    parser.feed(r.text)

    return "%(base)s/%(image)s" % {
        "base": base_url,
        "image": parser.get_image()
    }


def download_file(url, expected_name, force_redownload):
    versioned_url = get_versioned_image_link(url)
    actual_name = get_filename(versioned_url)

    if not os.path.isfile(actual_name) or force_redownload:
        # Get the sha of the file we are downloading - this file can be deleted
        # while we download the qcow, and this would cause us to see the file
        # as corrupted
        remote_sha = requests.get(versioned_url + '.sha256')

        try:
            os.system(
                "wget %(url)s -O %(file)s --progress=dot:giga" %
                { "url": versioned_url, "file": actual_name}
            )
            local_sha = os.popen('sha256sum %s' % actual_name).read()

            if local_sha.split(' ')[0] not in remote_sha.text:
                print("Local SHA: %s" % local_sha)
                print("Remote SHA: %s" % remote_sha.text)
                raise Exception("Download corrupted - please retry.")
        except:
            print("Deleting failed download")
            os.remove(actual_name)
            raise


    if not expected_name == actual_name:
        if os.path.islink(expected_name):
            os.unlink(expected_name)
        os.symlink(actual_name, expected_name)


def use_remote_file(url, force_redownload):
    expected_name = get_filename(url)
    download_file(url, expected_name, force_redownload)

def use_local_file(url):
    expected_name = get_filename(url)

    path = urlparse.urlparse(url).path

    cur_path = os.getcwd()

    print "%s/%s" % (cur_path, expected_name)

    if not "%s/%s" % (cur_path, expected_name) == path:
        if os.path.islink(expected_name):
            os.unlink(expected_name)
        os.symlink(path, expected_name)

def use_channel_file(url, docker_image_name, force_redownload):
    remote_url = get_channel_url(
        url=url,
        docker_image_name=docker_image_name)
    expected_name = urlparse.urlparse(url).netloc
    download_file(remote_url, expected_name, args.force_redownload)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Download CaaSP Image')
    parser.add_argument('url', metavar='url', help='URL of image to download')
    parser.add_argument(
        '--docker-image-name',
        metavar='docker_image_name',
        help='Name of the Docker derived image to download (eg: "sles12-velum-devel").')
    parser.add_argument('--skip', action='store_true')
    parser.add_argument('--force-redownload', action='store_true')
    args = parser.parse_args()

    if args.skip:
        raise SystemExit(0)

    if urlparse.urlparse(args.url).scheme in ['http', 'https']:
        use_remote_file(args.url, args.force_redownload)
    if urlparse.urlparse(args.url).scheme == "file":
        use_local_file(args.url)
    if urlparse.urlparse(args.url).scheme == "channel":
        use_channel_file(
            url=args.url,
            docker_image_name=args.docker_image_name,
            force_redownload=args.force_redownload)
