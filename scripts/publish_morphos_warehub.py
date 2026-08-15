"""Publish MorphOS warehub APK and update the listing on zibashu4.com."""
from __future__ import annotations

import json
import random
import string
import time
from pathlib import Path

import paramiko

HOST = "167.179.82.99"
USER = "root"
KEY = str(Path.home() / ".ssh" / "id_ed25519")
SITE = "/www/wwwroot/ziBashu4.com"

ANDROID_ROOT = Path.home() / "ANDROID"
APK_LOCAL = ANDROID_ROOT / "dist" / "morphos-v1.2.1-warehub.apk"
AAB_LOCAL = ANDROID_ROOT / "dist" / "morphos-v1.2.1-play.aab"
ICON_LOCAL = (
    ANDROID_ROOT / "apps" / "morphos" / "assets" / "brand" / "morphos_launcher_1024.png"
)

VERSION_NAME = "1.2.1"
VERSION_CODE = 16
SLUG = "morphos"
PACKAGE = "com.zibashu.morphos"


def rand_token(n: int = 6) -> str:
    return "".join(random.choice(string.ascii_lowercase + string.digits) for _ in range(n))


def main() -> None:
    if not APK_LOCAL.exists():
        raise SystemExit(f"Missing APK: {APK_LOCAL}")
    if not ICON_LOCAL.exists():
        raise SystemExit(f"Missing icon: {ICON_LOCAL}")

    ts = int(time.time())
    apk_name = f"android-{ts}-{rand_token()}.apk"
    icon_name = f"morphos-{ts}-{rand_token()}.png"
    remote_apk = f"{SITE}/storage/app/public/warehub/packages/zibashu/{apk_name}"
    remote_icon = f"{SITE}/storage/app/public/warehub/icons/{icon_name}"
    apk_rel = f"warehub/packages/zibashu/{apk_name}"
    icon_rel = f"warehub/icons/{icon_name}"
    size = APK_LOCAL.stat().st_size

    platforms = {
        "ios": {
            "url": None,
            "label": None,
            "distro": None,
            "source": "link",
            "channel": None,
            "enabled": False,
            "file_path": None,
        },
        "linux": {
            "url": None,
            "label": None,
            "distro": None,
            "source": "file",
            "channel": None,
            "enabled": False,
            "file_path": None,
        },
        "macos": {
            "url": None,
            "label": None,
            "distro": None,
            "source": "file",
            "channel": None,
            "enabled": False,
            "file_path": None,
        },
        "android": {
            "url": None,
            "label": "APK (warehub)",
            "distro": None,
            "source": "file",
            "channel": "apk",
            "enabled": True,
            "file_path": apk_rel,
        },
        "windows": {
            "url": None,
            "label": None,
            "distro": None,
            "source": "file",
            "channel": None,
            "enabled": False,
            "file_path": None,
        },
    }

    payload = {
        "slug": SLUG,
        "name": "MorphOS",
        "package_name": PACKAGE,
        "developer_name": "ziBashu",
        "short_description": "Personal adaptive environment — Home launcher, widgets, morph packs.",
        "description": (
            "MorphOS is the ziBashu family Home launcher. "
            "Sparse first home, glass dock, optional clock / weather / browser-search widgets, "
            "and notes stored as a file on the phone so they stay when you switch Home apps."
        ),
        "category": "tools",
        "content_rating": "everyone",
        "version_name": VERSION_NAME,
        "version_code": VERSION_CODE,
        "min_android": "24",
        "size_bytes": size,
        "icon_path": icon_rel,
        "screenshots": [],
        "apk_path": apk_rel,
        "platforms": platforms,
        "changelog": (
            f"v{VERSION_NAME}: App info / Select / Hide / Remove / Edit Homescreen, "
            "named folders, void occupancy, Morph shade, Smart Island, sidebar, "
            "all-apps name/icon/size."
        ),
        "tags": ["offline", "launcher", "home", "tools"],
        "is_featured": 1,
        "is_active": 1,
        "sort_order": 20,
    }

    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(HOST, username=USER, key_filename=KEY, timeout=30)
    sftp = client.open_sftp()

    print("upload APK ->", remote_apk)
    sftp.put(str(APK_LOCAL), remote_apk)
    print("upload icon ->", remote_icon)
    sftp.put(str(ICON_LOCAL), remote_icon)
    if AAB_LOCAL.exists():
        aab_remote = f"/opt/morphos/morphos-v{VERSION_NAME}-play.aab"
        print("archive AAB private ->", aab_remote)
        try:
            sftp.stat("/opt/morphos")
        except OSError:
            client.exec_command("mkdir -p /opt/morphos")
            time.sleep(0.4)
        sftp.put(str(AAB_LOCAL), aab_remote)

    remote_payload = f"/tmp/morphos-warehub-payload-{ts}.json"
    with sftp.open(remote_payload, "w") as f:
        f.write(json.dumps(payload))

    php_script = f"""<?php
require '{SITE}/vendor/autoload.php';
$app = require '{SITE}/bootstrap/app.php';
$app->make(Illuminate\\Contracts\\Console\\Kernel::class)->bootstrap();
$raw = file_get_contents('{remote_payload}');
$p = json_decode($raw, true);
if (!$p) {{ fwrite(STDERR, "bad payload\\n"); exit(1); }}
$now = date('Y-m-d H:i:s');
$data = [
  'slug' => $p['slug'],
  'name' => $p['name'],
  'package_name' => $p['package_name'],
  'developer_name' => $p['developer_name'],
  'short_description' => $p['short_description'],
  'description' => $p['description'],
  'category' => $p['category'],
  'content_rating' => $p['content_rating'],
  'version_name' => $p['version_name'],
  'version_code' => (int)$p['version_code'],
  'min_android' => $p['min_android'],
  'size_bytes' => (int)$p['size_bytes'],
  'icon_path' => $p['icon_path'],
  'screenshots' => json_encode($p['screenshots'] ?? []),
  'apk_path' => $p['apk_path'],
  'platforms' => json_encode($p['platforms']),
  'changelog' => $p['changelog'],
  'tags' => json_encode($p['tags'] ?? []),
  'is_featured' => (int)$p['is_featured'],
  'is_active' => (int)$p['is_active'],
  'sort_order' => (int)$p['sort_order'],
  'published_at' => $now,
  'updated_at' => $now,
];
$existing = Illuminate\\Support\\Facades\\DB::table('warehub_apps')->where('slug', $p['slug'])->first();
if ($existing) {{
  Illuminate\\Support\\Facades\\DB::table('warehub_apps')->where('slug', $p['slug'])->update($data);
  echo "UPDATED id={{$existing->id}}\\n";
}} else {{
  $data['created_at'] = $now;
  $data['downloads_count'] = 0;
  $data['rating_sum'] = 0;
  $data['rating_count'] = 0;
  $id = Illuminate\\Support\\Facades\\DB::table('warehub_apps')->insertGetId($data);
  echo "INSERTED id=$id\\n";
}}
@unlink('{remote_payload}');
$row = Illuminate\\Support\\Facades\\DB::table('warehub_apps')->where('slug', $p['slug'])->first();
echo 'ROW:' . json_encode($row) . "\\n";
"""
    remote_php = f"/tmp/morphos-warehub-upsert-{ts}.php"
    with sftp.open(remote_php, "w") as f:
        f.write(php_script)

    client.exec_command(
        f"chown www:www {remote_apk} {remote_icon} 2>/dev/null; "
        f"chmod 644 {remote_apk} {remote_icon}"
    )
    stdin, stdout, stderr = client.exec_command(f"php {remote_php}; rm -f {remote_php}")
    print(stdout.read().decode("utf-8", "replace"))
    err = stderr.read().decode("utf-8", "replace")
    if err.strip():
        print("ERR", err)

    import urllib.request

    for url in [
        f"https://zibashu4.com/hub/warehub/{SLUG}",
        f"https://zibashu4.com/hub/warehub/{SLUG}/download/android",
    ]:
        try:
            with urllib.request.urlopen(url, timeout=30) as resp:
                print(url, resp.status, resp.getheader("Content-Length"))
        except Exception as e:
            print(url, "FAIL", e)

    sftp.close()
    client.close()
    print("done")


if __name__ == "__main__":
    main()
