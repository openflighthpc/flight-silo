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

`repo list` will list accessible silos. Silos which exist locally but not upstream
are coloured yellow in this list.

`repo add` will add an existing silo to your system.

`repo create` will create a silo for your chosen provider. You can then add
your silo to other systems using the same credentials.

`repo edit` may be used to change the name or description of a silo. This updates
both the upstream and local silo data. If the name of the default silo is changed, 
that will also be updated.

`repo refresh` will update local silo metadata to match upstream data. A mismatch
could be created through use of `repo edit` on a different machine.

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

# Migration

Flight Silo Migration allows the user to migrate the installed silo softwares from an existing cluster to a new one.

## Concepts and Terms

In this section, some terms that relevant to the migration functions will be explained.

### Migration Item

A "migration item" is a single record that contains the name of a software, its version, which silo it is stored in, and which path it needs to be migrated to.

### Archive

An “archive” is a list of migration items. A migration lifecycle is to add migration items to an archive, save the archive to the cloud (i.e. silo repositories), get the archive on the new cluster, read the items stored in that archive, and pull the software correspondingly. Multiple archives can be created and switched between each other. Different archives can have different migration items, which might be different softwares stored different silo repositories, or the same softwares with different migration paths.

## Commands

This section lists the relevant commands to use the Flight Silo Migration, along with their available options.

### Command: migration view

This command is used to obtain an overview of the local migration status.

```
flight silo migration view # show the available archives and the migration item details of the enabled archive.
flight silo migration view --archive <archive id> # show the migration item details of the specific archive.
```

### Command: migration switch

This command is used to switch between archives.

```
flight silo migration switch # switch to a new archive, i.e. create an archive
flight silo migration switch --archive <archive id> # switch to an existing archive
```

### Command: migration pause & migration continue

By default, the migration item will automatically be added to or modified in the enabled archive when the software is pulled. However, you might not want to change the current archive. These two commands are used to control the migration monitoring.

```
flight silo migration pause # stop the migration monitoring
flight silo migration continue # start the migration monitoring
```

### Command: migration remove software

This command is used to remove an existing migration item from the archive.

```
flight silo migration remove software <name> <version> # remove a software item from the enabled archive
flight silo migration remove software <name> <version> --archive <archive id> # remove a software item from the specified archive
flight silo migration remove software <name> <version> --all # remove a software item from all archives that contains it
```

### Command: migration push

This command is used to save the local migration archives to the cloud.

```
flight silo migration push # push the local migration archives and use default silo for undefined archives
flight silo migration push --repo <silo name> # push the local migration archives and set a specific silo for those undefined archives.
```

### Command: migration pull

The local migration archives will be automatically synchronized when a new silo repository is added. However, later the cloud data might be changed through another cluster. This command is used to manually update the archives.

```
flight silo migration pull <silo name> # pull the archives from a silo
```

### Command: migration apply

This command is used by the cluster that wants to install the softwares based on the existing archive.

```
flight silo migration apply # install the softwares based on the enabled archive
flight silo migration apply --archive <archive id> # install the softwares based on the specified archive
flight silo migration apply --ignore-missing-item # install the existing softwares and ignore those do not exist.
flight silo migration apply --overwrite # overwrite the software if they have been installed locally under the same directory.
```

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
