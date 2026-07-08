"""Public API for rules_odin.

Users should load rules from this file:

    load("@rules_odin//odin:defs.bzl", "odin_binary", "odin_library", "odin_test")
"""

load("//odin/private:binary.bzl", _odin_binary = "odin_binary")
load("//odin/private:common.bzl", _OdinLibraryInfo = "OdinLibraryInfo")
load("//odin/private:library.bzl", _odin_library = "odin_library")
load("//odin/private:test.bzl", _odin_test = "odin_test")

odin_binary = _odin_binary
odin_library = _odin_library
odin_test = _odin_test
OdinLibraryInfo = _OdinLibraryInfo
