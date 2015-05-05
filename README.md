julia-matlab
============

This is a Matlab interface for calling [Julia](http://julialang.org),
an open-source language providing many features of a Matlab-like
environment but offering many of the performance benefits of C. The
primary purpose of this Matlab-Julia connector is present a way to
enhance performance in Matlab without the need for writing MEX files.

## NEWS

Since the author doesn't use this himself, this repository has not been maintained.
If you're interested in getting it working, you'll need to start from
a version of ZMQ that existed at the time this repository worked:
https://github.com/timholy/ZMQancient.jl

It's also very likely that changes in julia will require additional updates.

If you're willing to put the work into it, you are free to take "ownership"
(this is released under the MIT license).

## Installation and configuration

First, you need [ZeroMQ](http://www.zeromq.org) installed on your
machine.  ZeroMQ is an efficient cross-platform library (available for
Windows, Mac, and Linux) used for the communicaton between Matlab and
Julia.  It is assumed that this is installed as a system-wide library.
On (K)Ubuntu this can be installed simply using "apt-get install
libzmq1". At present, version 3 of ZeroMQ seems to be too buggy to
use, so you should make sure you're installing from the stable (2.x)
branch.

Second, from within Matlab navigate to the "mex" directory of this
repository and execute the ``make_mex`` script.  This will compile the
necessary MEX files.  You need a compiler on your system for this to
work.

Finally, configure your communications with Julia by running the
``julia_configure`` script.  This will allow you to define shortcuts
for both local Julia instances and instances running on remote
servers.  Naturally, you also have to have Julia installed, on every
machine that you plan to use.

## Using julia-matlab

For a local connection (which is the recommended way to start), you
can launch Julia from within Matlab using the ``juliastart`` command.
After that, read the help for ``juliacall``, ``juliaparse``, and
``juliasetvar``.  These are the three main commands that let you send
data to the Julia session, perform operations on it, and return the
results. Be aware that Julia will hold on to variables between calls,
so you can set up fairly elaborate computations with repeated calls.

For a remote connection, you'll need to launch Julia on the remote
machine, and then run the ``zmq_server_julia`` function.  If you've
changed any of the default ports in the Matlab ``julia_configure``
script, make sure you set the right values.  For example, if you
prefer to use port 5556, launch the server this way:

```Julia
julia> load("zmq_server_julia.jl")

julia> run_server("tcp://*:5556")
```

## Errors

Errors are typically reported back to the Matlab client. However, they
are also mirrored on the command line of the Julia server. For that
reason, if you have trouble you may prefer to launch Julia by hand
rather than letting Matlab launch it for you.

If communications between Matlab and Julia get interrupted, an easy
fix is often to kill the Julia instance and restart.

## Limitations

It would be nice to allow CTRL-C to gracefully interrupt and recover
the Julia communication. However, at present this is not implemented.

The most important part of the communication is the serializer (in
``juliaserialize.m``). This targets Julia's native
serializer. However, be aware that this is probably not the best
solution, and there have been proposals to use a more standards-based
serializer such as [Thrift](http://thrift.apache.org/) or the [IPython
Notebook](http://ipython.org/ipython-doc/dev/interactive/htmlnotebook.html).
If you are thinking of using this repository as a model for targeting
Julia from another language, you are advised to consider first working
with the Julia community to implement a more standards-based
serializer.
