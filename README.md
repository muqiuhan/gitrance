<div align="center">

![https://asciinema.org/a/4HojzjC21FEl6vt4Z54nrRUXJ](./demo.gif)

# Gitrance

*A collection of custom Bash scripts designed to enhance the Git command-line experience.*

</div>

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
        br = !"/path/to/gitrance/branch.sh"
    ```
    Replace `/path/to/gitrance` with the actual path where you cloned the repository.

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

## License

This project is licensed under the [BSD 3-Clause License](LICENSE). See the `LICENSE` file for details.
