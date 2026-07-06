"""Public API for rules_odin.

Users should load rules from this file:

    load("@rules_odin//odin:defs.bzl", "odin_binary")
"""

load("//odin/private:binary.bzl", _odin_binary = "odin_binary")

odin_binary = _odin_binary
