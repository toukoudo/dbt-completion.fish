# Copyright 2024 dbt Labs
# Copyright 2024 Makoto.Kimura
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# MODIFICATIONS:
# This file is a port of dbt-completion.bash to fish shell.
# Original bash version: https://github.com/dbt-labs/dbt-completion.bash
# Ported to fish shell by [Your Name] in 2024
#
# OVERVIEW
#   Adds autocompletion to dbt CLI by:
#       1. Finding the root of the repo (identified by dbt_project.yml)
#       2. Parsing target/manifest.json file, extracting valid model selectors
#       3. Providing autocompletion for selectors for:
#           -m
#           --model[s]
#           -s
#           --select
#           --exclude
#
# NOTE: This script uses the manifest (assumed to be at target/manifest.json)
#       to _quickly_ provide a list of existing selectors. As such, a dbt
#       resource must be compiled before it will be available for tab completion.
#       In the future, this script should use dbt directly to parse the project
#       directory and generate possible selectors. Until then, brand new
#       models/sources/tags/packages will not be displayed in the tab complete menu
#
# INSTALLATION
#   1. Create a symbolic link to your fish completions directory
#     ln -s (pwd)/dbt.fish ~/.config/fish/completions/dbt.fish
#
#     Or copy it if you prefer:
#     cp dbt.fish ~/.config/fish/completions/dbt.fish
#
#   2. Reload fish completions or restart fish
#     fish_update_completions
#
#   3. Use it with:
#     dbt run --models snow<tab>
#
#
# CREDITS
#   Ported from dbt-completion.bash
#   Original bash version credits:
#   - https://iridakos.com/tutorials/2018/03/01/bash-programmable-completion-tutorial.html
#   - Inspired by git-completion.bash

# Function to find dbt project root
function __dbt_get_project_root
    # Check if DBT_PROJECT_DIR is set and not empty
    if set -q DBT_PROJECT_DIR; and test -n "$DBT_PROJECT_DIR"
        echo $DBT_PROJECT_DIR
        return
    end

    # Walk up the filesystem until we find a dbt_project.yml file
    set -l directory (pwd)
    while test "$directory" != "/"
        if test -f "$directory/dbt_project.yml"
            echo $directory
            return
        end
        set directory (dirname $directory)
    end
end

# Function to parse manifest and extract selectors
function __dbt_parse_manifest
    set -l manifest_path $argv[1]
    set -l prefix ""
    if test (count $argv) -ge 2
        set prefix $argv[2]
    end

    # Python script to parse manifest.json
    set -l prog '
try:
    import json, sys

    prefix = sys.argv[1] if len(sys.argv) > 1 else ""

    with open(sys.stdin.fileno()) as f:
        manifest = json.load(f)

    models = set(
        "{}{}".format(prefix, node["name"])
        for node in manifest["nodes"].values()
        if node["resource_type"] in ["model", "seed"]
    )

    tags = set(
        "{}tag:{}".format(prefix, tag)
        for node in manifest["nodes"].values()
        for tag in node.get("tags", [])
        if node["resource_type"] == "model"
    )

    sources = set(
        "{}source:{}".format(prefix, node["source_name"])
        for node in manifest["nodes"].values()
        if node["resource_type"] == "source"
    ) | set(
        "{}source:{}.{}".format(prefix, node["source_name"], node["name"])
        for node in manifest["nodes"].values()
        if node["resource_type"] == "source"
    )

    fqns = set(
        "{}{}.*".format(prefix, ".".join(node["fqn"][:i-1]))
        for node in manifest["nodes"].values()
        for i in range(len(node.get("fqn", [])))
        if node["resource_type"] == "model"
    )

    selectors = [
        selector
        for selector in (models | tags | sources | fqns)
        if selector != ""
    ]

    for selector in selectors:
        print(selector)
except:
    pass
'

    if test -f "$manifest_path"
        cat "$manifest_path" | python -c $prog $prefix 2>/dev/null
    end
end

# Function to get selectors for completion
function __dbt_get_selectors
    set -l project_dir (__dbt_get_project_root)
    if test -z "$project_dir"
        return
    end

    # Attempt to fetch the manifest path from the environment variable
    set -l manifest_path
    if set -q DBT_MANIFEST_PATH; and test -n "$DBT_MANIFEST_PATH"
        set manifest_path $DBT_MANIFEST_PATH
    else
        set manifest_path "$project_dir/target/manifest.json"
    end

    # Check if manifest exists
    if not test -f "$manifest_path"
        return
    end

    # Get the current token to determine prefix
    set -l token (commandline -ct 2>/dev/null; or echo "")
    set -l prefix ""

    # Check for + or @ prefix
    if string match -qr '^[+@]' -- $token
        set prefix (string sub -l 1 -- $token)
    end

    __dbt_parse_manifest "$manifest_path" $prefix
end

# Check if the previous argument is a selector flag
function __dbt_is_selector_flag
    set -l cmd (commandline -opc)

    if test (count $cmd) -lt 2
        return 1
    end

    # Get the last flag before current position
    set -l last_flag ""
    for i in (seq (count $cmd) -1 1)
        set -l arg $cmd[$i]
        if string match -qr '^-' -- $arg
            set last_flag $arg
            break
        end
    end

    # Check if it's a selector flag
    switch $last_flag
        case -m --model --models -s --select --exclude
            return 0
        case '*'
            return 1
    end
end

# Define completions for dbt

# Model selector flags - provide custom completions via wrapper
# This ensures the function is called correctly during completion
function __dbt_complete_models
    __dbt_get_selectors
end

complete -c dbt -s m -x -a '(__dbt_complete_models)'
complete -c dbt -l model -x -a '(__dbt_complete_models)'
complete -c dbt -l models -x -a '(__dbt_complete_models)'
complete -c dbt -s s -x -a '(__dbt_complete_models)'
complete -c dbt -l select -x -a '(__dbt_complete_models)'
complete -c dbt -l exclude -x -a '(__dbt_complete_models)'

# Other common flags
complete -c dbt -l profiles-dir -r -d 'Directory to search for profiles.yml'
complete -c dbt -l profile -x -d 'Which profile to load'
complete -c dbt -l target -x -d 'Which target to load for the given profile'
complete -c dbt -l vars -x -d 'Supply variables to the project'
complete -c dbt -l threads -x -d 'Specify number of threads to use'
complete -c dbt -l no-version-check -f -d 'Skip the check for a newer version of dbt'
complete -c dbt -l project-dir -r -d 'Which directory to look in for the dbt_project.yml file'
complete -c dbt -l schema -x -d 'Specify the schema to load data into'
complete -c dbt -l full-refresh -f -d 'Drop and recreate incremental models and table models'
complete -c dbt -l fail-fast -f -d 'Stop execution upon a first failure'
complete -c dbt -s x -l fail-fast -f -d 'Stop execution upon a first failure'
complete -c dbt -l warn-error -f -d 'Convert dbt warnings into errors'
complete -c dbt -l defer -f -d 'Defer to state for references to unselected nodes'
complete -c dbt -l state -r -d 'Use previous state for modified comparison'

# Common dbt commands
complete -c dbt -n '__fish_use_subcommand' -a 'run' -d 'Execute dbt models'
complete -c dbt -n '__fish_use_subcommand' -a 'test' -d 'Execute dbt tests'
complete -c dbt -n '__fish_use_subcommand' -a 'build' -d 'Build and test selected resources'
complete -c dbt -n '__fish_use_subcommand' -a 'compile' -d 'Compile dbt models'
complete -c dbt -n '__fish_use_subcommand' -a 'seed' -d 'Load CSV files into database'
complete -c dbt -n '__fish_use_subcommand' -a 'snapshot' -d 'Execute dbt snapshots'
complete -c dbt -n '__fish_use_subcommand' -a 'debug' -d 'Show debug information'
complete -c dbt -n '__fish_use_subcommand' -a 'docs' -d 'Generate and serve documentation'
complete -c dbt -n '__fish_use_subcommand' -a 'source' -d 'Manage source freshness'
complete -c dbt -n '__fish_use_subcommand' -a 'init' -d 'Initialize a new dbt project'
complete -c dbt -n '__fish_use_subcommand' -a 'clean' -d 'Delete compiled files'
complete -c dbt -n '__fish_use_subcommand' -a 'deps' -d 'Download dependencies'
complete -c dbt -n '__fish_use_subcommand' -a 'list' -d 'List resources in the project'
complete -c dbt -n '__fish_use_subcommand' -a 'ls' -d 'List resources in the project'
complete -c dbt -n '__fish_use_subcommand' -a 'parse' -d 'Parse the project and generate a manifest'
complete -c dbt -n '__fish_use_subcommand' -a 'rpc' -d 'Run an RPC server'
complete -c dbt -n '__fish_use_subcommand' -a 'run-operation' -d 'Run a macro'
complete -c dbt -n '__fish_use_subcommand' -a 'show' -d 'Preview table rows or query results'

# docs subcommands
complete -c dbt -n '__fish_seen_subcommand_from docs' -a 'generate' -d 'Generate documentation'
complete -c dbt -n '__fish_seen_subcommand_from docs' -a 'serve' -d 'Serve documentation'

# source subcommands
complete -c dbt -n '__fish_seen_subcommand_from source' -a 'freshness' -d 'Check source freshness'
