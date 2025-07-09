# my_scripts

A collection of useful scripts.

## nu_install.sh

A script to install the latest version of nushell for linux environments. It will also add `nu` to your shell config file.

### Usage

To install nushell, run the following command:

```bash
curl -sSfL https://raw.githubusercontent.com/yuhua99/my_scripts/refs/heads/main/nu_install.sh | sh
```

The script will prompt you if you want to remove an existing nushell installation.

To remove nushell, run the following commands:

```bash
rm /usr/local/bin/nu
rm -rf ~/.config/nushell
```

You will also need to manually remove `nu` from your shell config file (e.g. `~/.bashrc` or `~/.profile`).

## fish_install.sh

A script to install the latest version of fish shell for linux environments. It will also add `fish` to your shell config file.

### Usage

To install fish shell, run the following command:

```bash
curl -sSfL https://raw.githubusercontent.com/yuhua99/my_scripts/refs/heads/main/fish_install.sh | sh
```

The script will prompt you if you want to remove an existing fish shell installation.

To remove fish shell, run the following commands:

```bash
rm /usr/local/bin/fish
rm -rf ~/.config/fish
```

You will also need to manually remove `fish` from your shell config file (e.g. `~/.bashrc` or `~/.profile`).

## link_lib.sh

This script finds the `MergedDir` of a Docker container and creates symbolic links to specified directories within the container'''s filesystem. This is useful for accessing libraries and include files from a container on the host machine.

### Usage

1.  Run the script:
    ```bash
    curl -sSfL https://raw.githubusercontent.com/yuhua99/my_scripts/refs/heads/main/link_lib.sh | bash
    ```
2.  The script will prompt you to enter a target directory for the symbolic links. The default is `/tmp/syno_include`.
3.  It will then list the running Docker containers and ask you to select one.
4.  The script will then create the symbolic links in the target directory.

You can also provide the target directory as an argument:

```bash
./link_lib.sh /path/to/your/target/directory
```
