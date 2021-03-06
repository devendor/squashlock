Squashlock Vault Script
=======================

`Squashlock on github`_

Squashlock is intended to run on Linux systems and provide secure locked repositories stored on
the filesystem as encrypted squash images with per-user/per-path destinations.

Filesystem and pid namespace protection provides a semi-containorized shell with access to your ipc
network and filesystem resources but not allowing access to it's own private mount pid space and
environment. This is accomplished via namespaces common to docker, lxd, lxc etc, but in a targeted
way to allow full access to everything else while protecting access to private resources.

Unencrypted qquash filestem only exists in a mnt namespace segmented tmpfs memory backed directory
in the container shell and is passed onto it's children. It is made writeable via an overlay, also
tmpfs/memory to prevent unecrypted data from ever touching disk.

When you exit the shell, the contents are checked for changes and re-squashed/encrypted if
via openssl rsa/aes256 smime if any changes have occured.  The re-squash process also keeps one
backup copy of the image before changes for safety.

Keys are stored as root under the squashlock install location.  Content remains securely on the
users filesystem where it can be pushed to revision control without conflicting with any one elses
secret images or being separated from your work.

It also functions as a pretty cool demonstration of namespace, openssl, and filesystem  vudu. On
another note...  Try lsns while you have chrome running, namespaces are not just for containers!

Use Case
--------

Stub out a connectivity config template for a proper test environment in the outer directory. Have
incoming devs set proper auth creds for their own rig in their individual squashlock vaults. Since
images are tagged by USER, individual settings can coexist securely in a shared git repository.

Check it in and unsquash it before starting your test processes.

Paths
-----

The "installation" is really just cloning whereever you want it to live, and optionally symlinking 
the script to somewhere in your PATH.

The derefernced path to the script determines the top dir for all support files and keys.

===================  =========================================================
   Path                  Description
===================  =========================================================
./squashlock         The script. Other paths are realative to this.
./keys/              Password protected private keys for vaults.
./history/           per vault log files show size, path, access, permissions
./links/             Links to the last known location of the vault.
./skel/              Contents Copied into new vaults at inception if it exists
./skel/.bash_logout  Default pre-seed file.
./skel/.bash_login   Default pre-seed file.
===================  =========================================================

By default, keys are stored as root  ./keys realative to the location of the squashlock script.

It's a good idea to back these up from time to time.  Using an existing vault should work anywhere
provided ./keys/user-key exists realtive to the script on the machine you envoke from.  If your
$USER changes, you will have to rename the key as per-user squashlock images key off of the
SUDO_USER environmental var with globbing.  ie: my vault is rferguson-*.squashlock etc. Of course
you will aslo need the password, linux, openssl, bash, and sudo. Git will also be required if you
want to take advantage of automatic revision control via .bash_(login|logout).

The pre-seed files created at initialization are itemized below.

==============   =========================================================  =========
  InVault                  Description                                       Source
==============   =========================================================  =========
./INFO           General info gathered at initialization.                   generated
./.bash_logout   Automatic git checkin inside squashfs.                     .skel/
./.bash_login    Provides runhome alias and other aliases for commands      .skel/
                 that expect real $HOME and autogit/logout setting.         generated
./.pub           The RSA public key for resquashing / encrypting.           generated
==============   =========================================================  =========

Modifications to the preseed files are persistent in each vault and defaults from ./skel can
be modified. The public key in the vault is own by root to prevent accidental deletion.
It can also be regenerated from the private via openssl if you have the password.


External App Note
-----------------

While you have full connectivity and can run any program with any type of file in here, you can't
be confident that a complex application isn't storing backups, history or cache insecurely
somewhere outside of the file in the squashlock path without doing your own homework. 

Usage
-----

.. code:: bash

  rferguson@mendota $ mdir secretPlace
  rferguson@mendota $ cd secretPlace
  rferguson@mendota $ echo initial_content > in_here
  rferguson@mendota $ sudo squashlock
  ... prompts to set initial passsword on key ...
  (secretPlace) rferguson@mendota $ # you are now in a shmem overlayfs above a squashfs in memory
  (secretPlace) rferguson@mendota $ echo secretThing >>in_here
  (secretPlace) rferguson@mendota $ scp ... ./more-secret-stuff
  (secretPlace)rferguson@mendota:~$ ps -ef
  UID        PID  PPID  C STIME TTY          TIME CMD
  root         1     0  0 09:08 pts/10   00:00:00 /bin/bash /usr/local/bin/squashlock
  root        46     1  0 09:08 pts/10   00:00:00 /sbin/runuser -ps /bin/bash rferguson
  rfergus+    47    46  0 09:08 pts/10   00:00:00 bash
  rfergus+    56    47  0 09:08 pts/10   00:00:00 ps -ef

  (secretPlace)rferguson@mendota:~$ df .
  Filesystem     1K-blocks  Used Available Use% Mounted on
  overlay         16425532    56  16425476   1% /home/rferguson/secretPlace

  (secretPlace)rferguson@mendota:~$ echo $HOME
  /home/rferguson/secretPlace

  (secretPlace)rferguson@mendota:~$ tail -3 /proc/mounts
  /dev/mapper/vg00-rferguson /tmp/.squashlock_pivot_9ngp ext4 rw,noatime,stripe=16,data=ordered 0 0
  /dev/loop3 /tmp/.squashlock_shm_GLYc/lower squashfs ro,relatime 0 0
  overlay /home/rferguson/secretPlace overlay rw,relatime,lowerdir=/tmp/.squashlock_shm_GLYc/lower,upperdir=/tmp/.squashlock_shm_GLYc/upper,workdir=/tmp/.squashlock_shm_GLYc/work 0 0
  (secretPlace)rferguson@mendota:~$ tail -4 /proc/mounts
  tmpfs /tmp/.squashlock_shm_GLYc tmpfs rw,relatime,mode=750 0 0
  /dev/mapper/vg00-rferguson /tmp/.squashlock_pivot_9ngp ext4 rw,noatime,stripe=16,data=ordered 0 0
  /dev/loop3 /tmp/.squashlock_shm_GLYc/lower squashfs ro,relatime 0 0
  overlay /home/rferguson/secretPlace overlay rw,relatime,lowerdir=/tmp/.squashlock_shm_GLYc/lower,upperdir=/tmp/.squashlock_shm_GLYc/upper,workdir=/tmp/.squashlock_shm_GLYc/work 0 0

  (secretPlace)rferguson@mendota:~$ exit

  rferguson@mendota $ ls
  rferguson@mendota:~/secretPlace$ ls
  in_here  rferguson_secretPlace_d1278c0c70c0077818c1c0419588795e.squashlocked
  rferguson@mendota $ cat in_here
  initial_content


Locked squash vaults have encrypted filesystems in the form of 

../path/to/thisvault/${USER}-thisvault-unique-id.squashlocked

This is created by simply changing into the directory and running squashlock for the first time.

Multiple users can have separate squashlocked files in the directory which is ideal for developers
collaborating on a project who may have different test enviroment settings they want to keep with
the work in revision control without leaking any secret data or clobbering eachothers settings.

Installation
------------

See Paths above for detail.

**Requirements:**

* linux
* sudo
* bash
* openssl
* git (recommended)

.. code:: shell

  chdir /opt # or whereever
  git clone https://github.com/devendor/squashlock.git
  chown -R root.root squashlock
  chmod g-w,o-rwx squashlock/squashlock
  # optional
  ln -s /opt/squaslock/squashlock /usr/local/bin
  mkdir squashlock/skel
  echo DEFAULT_THING > squashlock/skel/put_this_in_new_vaults


You may also want to modify sudoers to prevent double password prompting, once for sudo/system,
and again to unlock the decryption key. Sudo requires the dereferenced path to the script, not any
convenience symlink in PATH.

.. code::

  rferguson ALL=(ALL:ALL) NOPASSWD:/opt/squashlock/squashlock

.. _Squashlock on github: https://github.com/devendor/squashlock


