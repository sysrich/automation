#!/usr/bin/env python
try:
    import requests
except ImportError:
    print(" >> Please install python-requests")
    raise SystemExit(1)
import argparse
import urlparse
import os
import re
from HTMLParser import HTMLParser

URL_BASE = {
    'release': 'http://download.suse.de/ibs/SUSE:/SLE-12-SP3:/Update:/Products:/CASP20/',
    'staging_a': 'http://download.suse.de/ibs/SUSE:/SLE-12-SP3:/Update:/Products:/CASP20:/Staging:/A/',
    'staging_b': 'http://download.suse.de/ibs/SUSE:/SLE-12-SP3:/Update:/Products:/CASP20:/Staging:/B/',
    'devel': 'http://download.suse.de/ibs/Devel:/CASP:/2.0:/ControllerNode/',
}

QCOW_REGEX = '.*KVM.*x86_64-.*\.qcow2'
DOCKER_REGEX = '%(docker_image)s.*x86_64-.*\.tar\.xz'
OPENSTACK_REGEX = '.*OpenStack-Cloud.*x86_64-.*\.qcow2'
ISO_REGEX = '.*-DVD-x86_64-.*-Media1\.iso'


class ImageFinder(HTMLParser):

    def __init__(self, args):
        HTMLParser.__init__(self)
        self.images = set()

        if args.type == "docker":
            self.regexp = DOCKER_REGEX % {"docker_image": args.image_name}
        elif args.type == "kvm":
            self.regexp = QCOW_REGEX
        elif args.type == "openstack":
            self.regexp = OPENSTACK_REGEX
        elif args.type == "iso":
            self.regexp = ISO_REGEX
        else:
            print(" >> Unknown Image Type: " + args.type)
            raise SystemExit(1)

    def get_image(self):
        return self.images.pop()

    def handle_data(self, data):
        m = re.search(self.regexp, data)
        if m:
            self.images.add(m.group(0))


def use_local_file(args):
    expected_path = get_expected_path(args)
    actual_path = urlparse.urlparse(args.url).path

    if os.path.isfile(actual_path):
        link_file(actual_path, expected_path)
    else:
        print(" >> File not found: " + args.url)
        raise SystemExit(2)

def use_remote_file(args):
    download_file(args)
    link_file(get_actual_path(args), get_expected_path(args))

def use_channel_file(args):
    remote_url = get_channel_url(args)
    remote_canonical_url = get_canonical_url(args, remote_url)
    expected_path = urlparse.urlparse(args.url).netloc
    download_file(args, remote_canonical_url)
    link_file(get_actual_path(args, remote_canonical_url), get_expected_path(args, urlparse.urlparse(args.url).netloc))

## Util functions

# Local File Handling functions

def get_filename(url):
    return urlparse.urlparse(url).path.split('/')[-1]

def get_expected_path(args, filename=None):
    filename = filename or get_filename(args.url)

    if args.type == "docker":
        return os.path.abspath(
            "%(path)s/%(type)s-%(docker_image)s-%(filename)s" %
            {'path': args.path, 'filename': filename, 'type': args.type,
             'docker_image': args.image_name}
        )
    else:
        return os.path.abspath(
            "%(path)s/%(type)s-%(filename)s" %
            {'path': args.path, 'filename': filename, 'type': args.type}
        )

def get_actual_path(args, url=None):
    url = url or args.url
    return  os.path.abspath(
        "%(path)s/%(filename)s" %
        {'path': args.path, 'filename': get_filename(url)}
    )

def link_file(actual_path, expected_path):
    print(" >> File on Disk  : " + actual_path)
    if not expected_path == actual_path:
        print(" >> Static Path : " + expected_path)
        if os.path.islink(expected_path):
            os.unlink(expected_path)
        os.symlink(actual_path, expected_path)

# Remote Downloading functions

def get_canonical_url(args, url):
    proxies = {
      'http': args.proxy,
      'https': args.proxy,
    }

    image = requests.head(url, proxies=proxies)
    
    if image.status_code == 302 or image.status_code == 301:
        return get_canonical_url(args, image.headers.get('Location'))
    elif image.status_code == 200:
        return url
    else:
        raise Exception("Cannot find image location")

def download_file(args, canonical_url=None):
    canonical_url = canonical_url or get_canonical_url(args, args.url)
    expected_path = get_expected_path(args)
    actual_path = get_actual_path(args, canonical_url)

    if not os.path.isfile(actual_path):
        print(" >> Downloading File")
        print(" >> Remote File         : " + canonical_url)
        print(" >> Local File (On Disk): " + actual_path)

        proxies = {
          'http': args.proxy,
          'https': args.proxy,
        }

        try:
            remote_sha_pre = requests.get(canonical_url + '.sha256', proxies=proxies).text.split('\n')[3]

            proxy_flag =  '--no-proxy' if args.proxy == '' else '-e use_proxy=yes -e http_proxy=' + args.proxy

            os.system(
                "wget %(proxy_flag)s %(url)s -O %(file)s --progress=dot:giga" %
                { "url": canonical_url, "file": actual_path, "proxy_flag": proxy_flag}
            )

            local_sha = os.popen('sha256sum %s' % actual_path).read().split(' ')[0]
            remote_sha_post = requests.get(canonical_url + '.sha256', proxies=proxies).text.split('\n')[3]

            print(" >> Local SHA:                  %s" % local_sha)
            print(" >> Remote SHA (Pre Download):  %s" % remote_sha_pre)
            print(" >> Remote SHA (Post Download): %s" % remote_sha_post)

            if local_sha not in [remote_sha_post, remote_sha_pre]:
                print(" >> Download corrupted - please retry.")
                raise SystemExit(3)

        except:
            print(" >> Deleting failed download")
            os.remove(actual_path)
            raise

# Remote Parsing functions

def get_channel_url(args):

    channel = urlparse.urlparse(args.url).netloc

    parser = ImageFinder(args)

    if not URL_BASE.get(channel, False):
        raise Exception("Unknown channel: %s" % channel)

    base_url = URL_BASE[channel]
    if args.type == "docker":
        base_url += 'images_container_base'
    elif args.type in ["kvm", "openstack"]:
        base_url += 'images'
    elif args.type == "iso":
        base_url += 'images/iso'
    else:
        print(" >> Unknown Image Type: " + args.type)
        raise SystemExit(1)

    proxies = {
      'http': args.proxy,
      'https': args.proxy,
    }

    r = requests.get(base_url, proxies=proxies)
    parser.feed(r.text)

    return "%(base)s/%(image)s" % {
        "base": base_url,
        "image": parser.get_image()
    }



if __name__ == "__main__":

    parser = argparse.ArgumentParser(description='Download CaaSP Image')
    parser.add_argument('--type', choices=["docker", "kvm", "openstack", "iso"], help="Type of image to download", required=True)
    parser.add_argument('--path', help="Where should the image be downloaded and linked (default: '../downloads')", default='../downloads')
    parser.add_argument('--image-name', help='Name of the Docker derived image to download (eg: "sles12-velum-devel").')
    parser.add_argument('--proxy', help="Proxy server to use", default='')
    parser.add_argument('url', metavar='url', help='URL of image to download')
    args = parser.parse_args()

    if urlparse.urlparse(args.url).scheme in ['http', 'https']:
        use_remote_file(args)

    elif urlparse.urlparse(args.url).scheme == "file":
        use_local_file(args)

    elif urlparse.urlparse(args.url).scheme == "channel":
        if args.type in ["docker", "kvm", "openstack", "iso"]:
            use_channel_file(args)
        else:
            print(" >> Unknown Image Type: " + args.type)
            raise SystemExit(1)
    else:
        print(" >> Unknown URL Type: " + args.url)
        raise SystemExit(2)
