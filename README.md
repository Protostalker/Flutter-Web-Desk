# flutter_web_desk — slim Docker repackaging of RustDesk's web client

A slimmed-down Docker packaging of the [RustDesk](https://github.com/rustdesk/rustdesk) Flutter web client. Same app as [`keyurbhole/flutter_web_desk`](https://hub.docker.com/r/keyurbhole/flutter_web_desk) on Docker Hub, but with the runtime image shrunk from ~6 GB down to ~25 MB by dropping the Flutter SDK and C++ build toolchain that the original Dockerfile was baking in (those are only needed at build time, not runtime — `build/web/` is already pre-compiled).

**This is not original work.** The underlying application is RustDesk, an open-source remote desktop client. This repo just repackages a pre-built 2023 snapshot into a small nginx-based container to make self-hosting easier. All credit for the actual software goes to the RustDesk project and to keyurbhole for the original Docker packaging.

## Quick start (pre-built image)

Download `flutter_web_desk.tar.gz` from the [latest release](../../releases/latest), then on any Linux machine with Docker installed:

```bash
docker load -i flutter_web_desk.tar.gz

docker run -d \
  --name flutter_web_desk \
  -p 5003:80 \
  --restart unless-stopped \
  flutter_web_desk:v2
```

Open `http://<your-server-ip>:5003` in a browser — you should see the RustDesk web client's loading spinner.

## Build the image yourself from source

If you'd rather build the Docker image locally from the files in this repo:

```bash
docker build -t flutter_web_desk:v2 .

docker run -d \
  --name flutter_web_desk \
  -p 5003:80 \
  --restart unless-stopped \
  flutter_web_desk:v2
```

The build takes ~10 seconds because it's just copying the pre-compiled `build/web/` into an nginx:alpine image — there's nothing to compile.

## Useful commands

```bash
docker logs -f flutter_web_desk    # tail the server logs
docker stop flutter_web_desk       # stop it
docker rm flutter_web_desk         # remove the container
docker images                      # confirm the image is ~25 MB
```

## How it works

The `Dockerfile` uses `nginx:1.27-alpine` and serves `build/web/` as a static site. `nginx.conf` adds the things a Flutter web app needs for correct behaviour: gzip compression (`main.dart.js` is ~2.9 MB uncompressed), cache headers for hashed assets, and SPA fallback routing so Flutter's own router handles in-app paths. The default nginx mime.types (1.21+) already include `application/wasm`, so no custom MIME config is needed.

## What changed vs. upstream

Compared to the original `keyurbhole/flutter_web_desk` Docker image:

- `Dockerfile` — rewritten from scratch. The original installed Ubuntu 20.04 + the full Flutter SDK + `clang cmake ninja-build libgtk-3-dev` into the runtime image (hence 6 GB). The new one is nginx:alpine with a `COPY` of the pre-built output.
- `nginx.conf` — added. Replaces the old `python3 -m http.server` serve from `server/server.sh`.
- `Dockerfile.original` — kept for reference.
- `build/web/js/node_modules/` and `web/js/node_modules/` — removed. These were vite dev dependencies (~320 MB combined) that only matter at build time. They can be regenerated with `yarn install` if you ever want to rebuild the web JS bundle.

Everything else — `lib/` (Dart source), `assets/`, `web/`, `pubspec.yaml`, the iOS/Android build scripts — is unchanged from the 2023 snapshot.

## Rebuilding the web JS bundle

If you want to regenerate `web/js/dist/*.js` from source (e.g. to update dependencies):

```bash
cd web/js
yarn install          # restores node_modules
yarn build            # produces web/js/dist/index.js and vendor.js
```

Then you'd need to `flutter build web` to produce a fresh `build/web/` — that requires a working Flutter SDK, see [flutter.dev/get-started](https://docs.flutter.dev/get-started/install).

## Caveats

This is a **2023 snapshot**. The RustDesk protocol may have drifted since then — the web client might not negotiate correctly against a current-version RustDesk server. Spin it up and test against your own server before investing in fancier hosting.

The `build/web/index.html` contains RustDesk's Firebase analytics keys, shipped unchanged from the upstream build. They're not secrets (every RustDesk web client ships them publicly), but if you'd rather not send analytics pings to RustDesk's Firebase project, strip the `firebase.initializeApp(...)` block from `build/web/index.html` before building the image.

## License

[GNU Affero General Public License v3.0 (AGPL-3.0)](./LICENSE), inherited from upstream RustDesk. AGPL is a strong copyleft license: any modifications or network-deployed versions must also be released under AGPL-3.0 with source available. See the `LICENSE` file for the full text.

## Credits

- [RustDesk](https://github.com/rustdesk/rustdesk) — the actual application. All the real engineering lives there.
- [keyurbhole/flutter_web_desk](https://hub.docker.com/r/keyurbhole/flutter_web_desk) — the original Docker packaging this fork inherited from.
