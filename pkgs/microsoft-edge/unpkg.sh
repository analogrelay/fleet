source="$1"
pkg_name="$2"
output_dir=$(pwd)

unpack_dir="$TMPDIR/unpack1"
mkdir "$unpack_dir"
cd "$unpack_dir"
xar -xf "$source"
cd "$pkg_name"
pkg_dir=$(pwd)

content_dir="$TMPDIR/content"
mkdir "$content_dir"
cd "$content_dir"
cat "$pkg_dir/Payload" | gunzip -dc | cpio -i