def network_names(container):
    return list(container.attrs['NetworkSettings']['Networks'])


def get_network_by_name(container, name, partial=False):
    for network_name in network_names(container):
        if name == network_name:
            return network_name
        elif partial and name in network_name:
            return network_name
