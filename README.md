# Gitrance

This project contains a collection of custom Bash scripts designed to enhance the Git command-line experience. These scripts provide beautified output and a more intuitive interface.

## Usage

1.  **Clone the repository**: Clone this repository to your local machine:

    ```bash
    git clone https://github.com/muqiuhan/gitrance.git
    cd gitrance
    ```

2.  **Set executable permissions**: Grant execute permissions to the scripts:

    ```bash
    chmod +x diff-stat.sh log.sh status.sh
    ```

3.  **Set up Git Aliases**: Instead of adding the scripts to your PATH, it is highly recommended to set up Git aliases for easier access. This allows you to run `git dst`, `git lg`, and `git st` directly from your terminal.

    Open your Git configuration file (e.g., `~/.gitconfig`) and add the following aliases:

    ```ini
    [alias]
        dst = !"/path/to/gitrance/diff-stat.sh"
        lg = !"/path/to/gitrance/log.sh"
        st = !"/path/to/gitrance/status.sh"
    ```
    Replace `/path/to/gitrance` with the actual path where you cloned the repository.

### How to Use

Once the aliases are set up, you can use the enhanced commands as follows:

*   **`git dst`**: Runs `diff-stat.sh`, optionally followed by any `git diff` arguments.
    ```bash
    git dst
    git dst HEAD~1 HEAD
    git dst --cached
    ```

*   **`git lg`**: Runs `log.sh`, optionally followed by any `git log` arguments.
    ```bash
    git lg
    git lg -n 5
    git lg --author="Your Name"
    ```

*   **`git st`**: Simply runs `status.sh`.
    ```bash
    git st
    ```

## Configuration

The color definitions, emojis, and certain display parameters for all scripts can be configured at the top of each script file. You can customize them by directly editing the `--- configuration (can be customized here) ---` section.

For example, in `diff-stat.sh`:

```bash
# color definitions
COLOR_NC='\033[0m'
COLOR_RED='\033[0;31m'
# ...

# summary analysis graph configuration
BAR_WIDTH=40
GREEN_BLOCK="∎"
# ...

# file level visualization configuration
CIRCLE="●"
MAX_CIRCLES=10
```

## Scripts

### status

```
>git st
 🌿  On branch master [Up-to-date with origin/master]


Unstaged changes:
    📝  modified:   global.json [+1, -1]
    📝  modified:   samples/Argu.Samples.LS/Argu.Samples.LS.fsproj [+5, -1]
```

```
> git st
 🌿  On branch master [⬇️ 2 Behind | origin/master]
 📊  Staged changes summary: +10, -6 ∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎

Staged changes:
    ✅  modified:   Directory.Packages.props [+5, -5]
    ✅  modified:   RELEASE_NOTES.md [+4, -0]
    ✅  modified:   tests/Argu.Tests/Argu.Tests.fsproj [+1, -1]
```

### diff --stat

```
> git dst 6.2.0
Diff summary for: git diff 6.2.0
 📊  Total: +133, -62 ∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎

File changes:
  .config/dotnet-tools.json  [●●●●  +2, -2]
  Directory.Packages.props  [●●●●●●  +6, -6]
  RELEASE_NOTES.md  [●●●●●●●  +19, -2]
  docs/index.fsx  [●●  +1, -1]
```

## log

```
> git lg
* ➜ d641dea 📍 HEAD -> main ☁️ origin/main ☁️ origin/HEAD [build]: .....  👤 Muqiu Han  ⏰ 8 months ago
*   ➜ 470718f Merge pull request #14 from X-FRI/main  👤 Muqiu Han  ⏰ 10 months ago
|\
| * ➜ 0ab19f0 [core]: add Node::remove_item_from_leaf  👤 Muqiu Han  ⏰ 10 months ago
| * ➜ a37c77f [core]: fix collection bugs and some security fixes.  👤 Muqiu Han  ⏰ 10 months ago
| * ➜ b6e4dc9 [core]: fix node serializer error.  👤 Muqiu Han  ⏰ 10 months ago
|/
*   ➜ 8aa6852 Merge pull request #13 from X-FRI/main  👤 Muqiu Han  ⏰ 11 months ago
|\
| * ➜ 55555d3 [core]: A lot of detail optimization and test error fixes.  👤 Muqiu Han  ⏰ 11 months ago
| * ➜ 80ed26a [core]: optimize data_access_layer and node and test it.  👤 Muqiu Han  ⏰ 11 months ago
| * ➜ d289bec [core]: fix data_access_layer tests.  👤 Muqiu Han  ⏰ 11 months ago
| * ➜ dc3fb61 [libs]: fix endian deps  👤 Muqiu Han  ⏰ 11 months ago
| * ➜ 5d016a1 [core]: fix endian deps, remove extra files.  👤 Muqiu Han  ⏰ 11 months ago
|/
*   ➜ b8dfcef Merge pull request #12 from X-FRI/main  👤 Muqiu Han  ⏰ 11 months ago
```

## License

This project is licensed under the [BSD 3-Clause License](LICENSE). See the `LICENSE` file for details.
