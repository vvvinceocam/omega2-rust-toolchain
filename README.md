# omega2-rust-toolchain

Rust toolchain for the [Onion Omega2 SBC](https://onion.io/Omega2/).

## Usage

Define an alias:

```
$ alias omega2-rust-toolchain='docker run --rm -v"$PWD:/home/rust/project" -it vberset/omega2-rust-toolchain:latest'
```

Thus, to compile your project, simply run:

```
$ omega2-rust-toolchain cargo build --release
```

You can also open a shell in the projet:

```
$ omega2-rust-toolchain bash
```
