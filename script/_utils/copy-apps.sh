app_folder=$1
source_folder=$2

if [ -z "$app_folder" ]; then
  echo "Usage: copy-apps.sh <target app folder> <source folder>"
  exit 1
fi

if [ -z "$source_folder" ]; then
  echo "Usage: copy-apps.sh <target app folder> <source folder>"
  exit 1
fi

echo "Copying apps from $source_folder in to $app_folder ..."

verbose() {
  if [ -n "${VERBOSE:-}" ]; then
    echo "$@"
  fi
}

warning() {
  echo "$@" 1>&2
}

clean_folder() {
  # Some files end up not writable by the owner, but we _are_ the owner and can override that.
  $DRY_RUN_CMD chmod -R u+w "$1"
  $DRY_RUN_CMD rm -Rf "$1"
}

copy_app() {
  local source=$1
  local target=$2
  local name=$3
  local copies_file=$4

  if [ -d "$target" ]; then
    clean_folder "$target"
  fi

  $DRY_RUN_CMD cp -R "$source" "$target"
  
  if [ -z "${DRY_RUN:-}" ]; then
    echo $source > "$copies_file"
  fi

  verbose "Copied $source to $target and recorded source in $copies_file"
}

copies_folder="$app_folder/.copies"
old_copies_folder="$app_folder/.copies.old"
if [ -d $copies_folder ]; then
  mv $copies_folder "$app_folder/.copies.old"
fi
mkdir $copies_folder

process_app() {
  local source_app=$1
  verbose "Processing $source_app ..."

  app_name=$(basename "$source_app")
  copy_metadata_path="$copies_folder/${app_name}.src"
  old_copy_metadata_path="$old_copies_folder/${app_name}.src"
  target_path="$app_folder/$app_name"

  # If the copied app doesn't exist...
  if [ ! -d "$target_path" ]; then
    # copy it
    echo "Copying $source_app to $target_path"
    copy_app "$source_app" "$target_path" "$app_name" "$copy_metadata_path"
    return
  fi

  # If the original metadata file doesn't exist, it was installed some other way.
  if [ ! -f "$old_copy_metadata_path" ]; then
    warning "FAILED to copy $app_name, it already exists at $target_path but wasn't installed via Nix"
    return
  fi

  # Check the old copy metadata, to see if the app comes from a new derivation
  existing_derivation=$(cat "$old_copy_metadata_path")

  if [ "$existing_derivation" = "$source_app" ]; then
    # Just copy the old copy metadata over.
    $DRY_RUN_CMD cp "$old_copy_metadata_path" "$copy_metadata_path"
    verbose "Skipping $app_name as it comes from the same derivation as the existing app copy"
    return
  fi

  # Update the copy!
  echo "Updating $app_name as it was previously from $existing_derivation but is now from $source_app"
  copy_app "$source_app" "$target_path" "$app_name" "$copy_metadata_path"
}

# Special case: If there's only 1 app, the source folder _is_ a symlink directly to that derivation
if [ -L "$source_folder" ]; then
  find "$source_folder/" -maxdepth 1 -mindepth 1 -type d | while read source_app
  do
    process_app "$source_app"
  done
else
  # Compute the new list of copies by hashing all the existing apps.
  find "$source_folder" -type l -exec readlink -f {} \; | while read source_app
  do
    process_app "$source_app"
  done
fi

# Find each file in the old copies path that doesn't exist in the new copies path
if [ -d "$old_copies_folder" ]; then
  find "$old_copies_folder" -type f | while read old_copy_metadata_path
  do
    app_name=$(basename "$old_copy_metadata_path" | sed 's/\.src$//g')
    copy_metadata_path="$copies_folder/${app_name}.src"

    if [ ! -f "$copy_metadata_path" ]; then
      echo "Cleaning old copy of $app_name because it is no longer in the list of installed apps"
      clean_folder "$app_folder/$app_name"
    fi
  done

  # Clean up the old copies folder
  $DRY_RUN_CMD rm -Rf "$old_copies_folder"
fi