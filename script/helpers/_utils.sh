fleet_debug=false
fleet_ansible_args=()

ensure_bootstrapped() {
    if ! type python3 >/dev/null 2>&1; then
        echo "You got to install python3 manually, sorry."
        exit 1
    fi

    if [ ! -f ".venv/bin/activate" ]; then
        echo "No virtual environment found, run 'script/bootstrap' first"
        exit 1
    fi
}

enable_debug() {
    fleet_debug=true
}

debug() {
    if "$fleet_debug"; then
        echo "$@"
    fi
}

select_host() {
    fleet_target_host="$1"
    if [ -z "$fleet_target_host" ]; then
        echo "No host specified. Usage: 'script/apply [host]|me'"
        exit 1
    fi

    fleet_target_local=false
    if [ "$fleet_target_host" = "me" ]; then
        fleet_target_host=$(hostname | sed 's/\.lan//g')
        fleet_target_local=true
    fi

    if $fleet_target_local; then
        fleet_ansible_args+=("-e" "ansible_connection=local")
    fi
}