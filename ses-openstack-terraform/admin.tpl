#!/bin/bash

zypper --non-interactive --quiet --gpg-auto-import-keys ar -f ${sles_base} sles_base
zypper --non-interactive --quiet --gpg-auto-import-keys ar -f ${sles_update} sles_update
zypper --non-interactive --quiet --gpg-auto-import-keys ar -f ${ses_base} ses_base
zypper --non-interactive --quiet --gpg-auto-import-keys ar -f ${ses_update} ses_update