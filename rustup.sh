#!/bin/bash

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
  sh -s -- --no-modify-path --default-toolchain none
