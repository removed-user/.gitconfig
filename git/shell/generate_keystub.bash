#!/usr/bin/env bash
function generate_keystub() {
  ssh-keygen -K \
  -f ~/.ssh/id_"${KEY_TYPE}"_"${APPLICATION}"
}
