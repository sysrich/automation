#!/bin/bash

zypper --non-interactive --quiet --gpg-auto-import-keys ar -f ${sles_base} sles_base
zypper --non-interactive --quiet --gpg-auto-import-keys ar -f ${sles_update} sles_update
zypper --non-interactive --quiet --gpg-auto-import-keys ar -f ${containers_module_base} containers-module_base
zypper --non-interactive --quiet --gpg-auto-import-keys ar -f ${containers_module_update} containers-module_update