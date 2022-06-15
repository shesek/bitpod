#! -- expected to be 'source'd
set -eo pipefail

echo '🟢 setting up symlinks'
mkdir -p /workspace/{bin,datadir}

ln -s /workspace/bitpod/bitcoin.conf /workspace/datadir/

# Symlink git submodules to be available directly under /workspace
ln -s /workspace/bitpod/{bitcoin,btcdeb,btc-rpc-explorer} /workspace

# Make bitpod available within the bitcoin core directory, so its easily accessible in the editor
ln -s /workspace/bitpod /workspace/bitcoin/.bitpod

ln -s /workspace/bitcoin/src/bitcoin{d,-cli,-tx,-util,-wallet} /workspace/bin/
if [ -n "$WITH_GUI" ]; then
  ln -s /workspace/bitcoin/src/qt/bitcoin-qt /workspace/bin/
fi

ln -s /workspace/bitpod/bitcoin-build.sh /workspace/bin/bitcoin-build
ln -s $(which llvm-cov-15) /workspace/bin/llvm-cov
#hash -r

# Use the ~/.pyenv directory created during the docker build,
# but move it to /workspace so that changes are persisted.
rm -rf /workspace/.pyenv
mv /home/gitpod/.pyenv /workspace

# Bitcoin Core's Python version will typically already be installed by the Dockerfile, but it is
# re-installed jere in case .python-version uses a different version (the Dockerfile hardcodes v3.6.12)
echo '🟢 installing python '   $(cat /workspace/bitcoin/.python-version)
pyenv install -s -v $(cat /workspace/bitcoin/.python-version)
pyenv versions

echo '🟢 setting up bitcoin git repo'
(cd /workspace/bitcoin &&
  git remote add upstream https://github.com/bitcoin/bitcoin)
(cd /workspace/bitpod/.git/modules/bitcoin &&
  rm info/exclude && ln -s /workspace/bitpod/.gitignore.global info/exclude)

[ -n "$NO_BUILD" ] || bitcoin-build
[ -z "$BTCDEB" ] || btcdeb-build