# Flight Silo

Persistent storage for ephemeral instances.

## Overview

Flight Silo allows users to connect to "silos" - cloud storage systems designed 
primarily to distribute software and projects, with more general file storage 
also available. 

## Installation

Installation via git:

```
git clone https://github.com/openflighthpc/flight-silo.git
cd flight-silo
bundle install
```

## Configuration

Flight Silo has some optional configuration settings available. A 
`config.yml.ex` file exists which gives examples of all configuration keys.

## Operation

### Setting up a silo

Use `type avail` to list available provider types, and use `type prepare` to 
prepare any required types.

`repo avail` will list accessible silos.

`repo add` will add an existing silo to your system.

`repo create` will create a silo for your chosen provider. You can then add
your silo to other systems using the same credentials.

`repo remove` will remove the silo metadata from your system, while
`repo delete` will destroy the upstream silo (requiring confirmation to do so).

### Interacting with files

The `file list` and `file pull` commands can list and pull files respectively. 
When specifying a file or directory in a silo, the format is `silo:path`, e.g. 
`my-silo:/pictures/art.png`. If the silo name is not given, the default silo 
will be used instead (the default silo may be changed in `config.yml`). If a 
local file path is missing as an argument, the current working directory is used.

Files and directories can be deleted from a silo with `file delete`. The
`--recursive` option is required to delete directories.

Files and directories can be pushed to a silo with `file push`. The
specification for remote locations is the same as the `pull` command.

### Interacting with softwares

Flight Silo can store `.tar.gz` files, called "softwares", with a name and a
version number attached to them.

You can push a software to a silo with `software push FILE NAME VERSION`. The
value given to `VERSION` must be a set of alphanumeric characters separated by 
period characters. All characters preceding the first period (if it exists) must
be integer digits. For example, the following version numbers are all valid:

```
1
1.0
0.1.0
0.a
1.1a
```

Once uploaded, softwares can be pulled onto any machine with access to the silo.
The previously uploaded tarball will be downloaded and extracted to your given
softwares directory.

# Contributing

Fork the project. Make your feature addition or bug fix. Send a pull
request. Bonus points for topic branches.

Read [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

# Copyright and License

Eclipse Public License 2.0, see [LICENSE.txt](LICENSE.txt) for details.

Copyright (C) 2023-present Alces Flight Ltd.

This program and the accompanying materials are made available under
the terms of the Eclipse Public License 2.0 which is available at
[https://www.eclipse.org/legal/epl-2.0](https://www.eclipse.org/legal/epl-2.0),
or alternative license terms made available by Alces Flight Ltd -
please direct inquiries about licensing to
[licensing@alces-flight.com](mailto:licensing@alces-flight.com).

Flight Silo is distributed in the hope that it will be
useful, but WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER
EXPRESS OR IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR
CONDITIONS OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR
A PARTICULAR PURPOSE. See the [Eclipse Public License 2.0](https://opensource.org/licenses/EPL-2.0) for more
details.
