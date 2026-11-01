"""Tiny non-executable Mach-O structures for negative delivery checks only."""
import plistlib
import struct


def macho(filetype, commands, platform=2):
    build = struct.pack("<IIIIII", 0x32, 24, platform, 0, 0, 0)
    payload = build + b"".join(commands)
    return struct.pack("<IIIIIIII", 0xFEEDFACF, 0x0100000C, 0, filetype,
                       len(commands) + 1, len(payload), 0, 0) + payload


def path_command(command, path):
    header = 12 if command == 0x8000001C else 24
    size = (header + len(path.encode()) + 1 + 7) // 8 * 8
    raw = struct.pack("<III", command, size, header) + bytes(header - 12) + path.encode() + b"\0"
    return raw.ljust(size, b"\0")


def add_fixture_native_runtime(app, executable_name):
    install_name = "@rpath/llama.framework/llama"
    (app / executable_name).write_bytes(macho(2, [path_command(0xC, install_name),
        path_command(0x8000001C, "@executable_path/Frameworks")]))
    framework = app / "Frameworks/llama.framework"
    framework.mkdir(parents=True)
    (framework / "llama").write_bytes(macho(6, [path_command(0xD, install_name)]))
    (framework / "Info.plist").write_bytes(plistlib.dumps({"CFBundleExecutable": "llama", "CFBundlePackageType": "FMWK"}))
    (framework / "LICENSE").write_text("MIT license fixture; no native code")
    (framework / "THIRD_PARTY_NOTICES.txt").write_text("Fixture identity: dde879bc4f954b809892fd0d660515f42536394a")
