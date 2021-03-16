#!/usr/bin/env bash
# this is a work around to make sure we have
# our keyfile available
echo $KEY_MATERIAL > deploy_keyfile
chmod 0600 deploy_keyfile
