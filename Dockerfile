# Slim runtime image: just nginx serving the pre-built Flutter web output.
# No Flutter SDK, no Ubuntu base, no C++ toolchain — the build/web/ output
# is already compiled and all we need is a static file server.
#
# Final image size: ~25 MB (vs. ~6 GB for the original Dockerfile).

FROM nginx:1.27-alpine

# Replace the default nginx config with one that handles .wasm MIME types
# and enables gzip (main.dart.js is ~2.9 MB uncompressed).
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy the pre-built Flutter web output into nginx's document root.
COPY build/web/ /usr/share/nginx/html/

EXPOSE 80

# nginx:alpine's default CMD already starts nginx in the foreground.
