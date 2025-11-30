# dbt-completion.fish

Fish shell completion for [dbt](https://www.getdbt.com/) (data build tool).

This is a port of [dbt-completion.bash](https://github.com/dbt-labs/dbt-completion.bash) to the fish shell.

## Features

- Autocomplete for dbt commands (run, test, build, etc.)
- Autocomplete for model selectors after `--models`, `-m`, `--select`, `-s`, `--exclude` flags
- Supports model names, tags, sources, and FQN patterns
- Supports graph operators (`+`, `@`)

## Installation

### Using Fisher (recommended)

If you have [Fisher](https://github.com/jorgebucaran/fisher) installed:

```fish
fisher install toukoudo/dbt_completion
# & restart shell
```

### Manual installation

```fish
# Create a symbolic link to your fish completions directory
ln -s (pwd)/completions/dbt.fish ~/.config/fish/completions/dbt.fish

# Reload fish completions
fish_update_completions
```

Or copy the file:

```fish
cp completions/dbt.fish ~/.config/fish/completions/dbt.fish
fish_update_completions
```

## Usage

```fish
dbt run --models <TAB>        # Autocomplete model names
dbt test --select my<TAB>     # Autocomplete models starting with 'my'
dbt build -m +<TAB>           # Autocomplete with + prefix
```

## Requirements

- fish shell
- Python (for parsing manifest.json)
- A compiled dbt project (target/manifest.json must exist)

## Environment Variables

- `DBT_PROJECT_DIR`: Override the automatic project root detection
- `DBT_MANIFEST_PATH`: Override the default manifest path (default: `target/manifest.json`)

## License

Copyright 2024 dbt Labs
Copyright 2024 [Your Name]

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

See [LICENSE](LICENSE) for the full license text.

## Acknowledgments

This project is a derivative work based on [dbt-completion.bash](https://github.com/dbt-labs/dbt-completion.bash) by dbt Labs.
Ported to fish shell by [Your Name] in 2024.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
