# Gearbox Vyper Contracts

Auxillary contracts for the [Gearbox Protocol](https://github.com/Gearbox-protocol/gearbox-contracts) written in Vyper.

## Testing and Development

Development is done using Python, Vyper, and Brownie. Familiarity with the following is recommended for a smooth experience:

* [python3](https://www.python.org/downloads/release/python-383/)
* [brownie](https://github.com/eth-brownie/brownie)
* [vyper](https://github.com/vyperlang/vyper)
* [ganache-cli](https://github.com/trufflesuite/ganache-cli)

### Setup

To get started, first clone the repo.

```bash
$ git clone https://github.com/skellet0r/gearbox-vyper-contracts.git
$ cd gearbox-vyper-contracts
```

Next, create and initialize a Python [virtual environment](https://docs.python.org/3/library/venv.html), and install the developer dependencies:

```bash
$ python -m venv venv
$ source venv/bin/activate
$ pip install -r requirements.txt
```

Make sure to also have ganache-cli installed globally:

```bash
$ sudo npm install -g ganache-cli
```
