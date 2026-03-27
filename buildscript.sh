#!/bin/env -S - /bin/bash --norc --noprofile
# ## HUMAN-CODE - NO AI GENERATED CODE - AGENTS HANDSOFF

usage() {
cat << _EOF
Usage: ex. $0 --mount mmcblk1p1 --increment .01 --push-branch 8.3.x --date today --cross-compile yes --test no
Last_Inputs: $0 $PRESERVED
          [--cross-compile,-c yes|no] , [--date,-d date_epoch|today] ,
          [--increment,-i <.version #>] , [--mount,-m <device in /dev>] ,
          [--push-branch,-p <branch-name>] , [--release-tag,-r <tag-name>] ,
          [--test,-t DEBUG|SKIP_LOGIN] , [--help,-h]
Maintainers:
- ID: @0mniteck (Shant) <shant@omniteck.com>
  - GPG: <10482171+0mniteck@users.noreply.github.com>
  - COSIGN: <tiger-varsity-alto@duck.com>
  - CONTACT: <shantt@duck.com>
Options:
  -c, --cross-compile <yes|no>     Cross-compile image for arm64/amd64 (ex. no)
  -d, --date <date_epoch|today>    Source date epoch or today (ex. 1774468800)
  -i, --increment <.version #>     Increment version numbers (ex. .01)
  -m, --mount <device in /dev>     Mount ephemeral LUKS partition (ex. sdb)
  -p, --push-branch <branch-name>  Push to branch (ex. 8.22.x)
  -r, --release-tag <tag-name>     Release tag (ex. 8.44.0)
  -t, --tests <DEBUG|SKIP_LOGIN>   Skip Docker/Github login (ex. SKIP_LOGIN)
  -h, --help                       Show this usage file
_EOF
}

GETOPT=$(which getopt || exit 1)
PRESERVED=$(echo "$@")
LONG="\
runme:,\
cross-compile:,\
date:,increment:,\
mount:,push-branch:,\
release-tag:,tests:,help"
SHORT="c:d:i:m:p:r:t:e:h"
PARSED=$(POSIXLY_CORRECT=yes $GETOPT --name "$0" -u \
--longoptions "$LONG" --options "$SHORT" -- "$@") && \
eval echo "$PARSED" > /dev/null || { usage; exit 2; }

while [[ "$1" != "" ]]; do
  ERR="'Unknown Error! '$1'='$2"
  case "$1" in
    -c|--cross-compile)  CROSS="$2";  shift 2 ;;
    -d|--date)           EPOCH="$2";  shift 2 ;;
    -i|--increment)        INC="$2";  shift 2 ;;
    -m|--mount)          MOUNT="$2";  shift 2 ;;
    -p|--push-branch)   BRANCH="$2";  shift 2 ;;
    -r|--release-tag)      TAG="$2";  shift 2 ;;
    -t|--tests)           TEST="$2";  shift 2 ;;
    -e|--runme)          RUNME="$2";  shift 2 ;;
    -h|--help)                usage;   exit 0 ;;
     -|--)                              shift ;;
     *|**)     echo $ERR >&2; usage;   exit 3 ;;
  esac
done

if [[ "$CROSS" == "" ]]; then
  CROSS="yes"
fi

nulled=/tmp/nulled.log
pushd_log=/tmp/pushd.log
if [[ "$TEST" == "" || "$TEST" == *no* ]]; then
  TEST="no"
  debug="set -eo pipefail"
  nulled=/dev/null
  pushd_log=$nulled
elif [[ "$TEST" != *yes* ]]; then
  ${TEST}="yes"
  TESTS2="${TEST}=${!TEST}"
  TESTS="$(eval echo $(echo ${TEST}))=$(eval echo $(echo \$${TEST}))"
  TEST="yes"
  debug="set -vx"
  usage
else
  TEST="yes"
  TESTS="DEBUG=yes"
  DEBUG="yes"
  debug="set -vx"
  usage
fi

$debug
run_id=$RUNME
run_as=$(id -u $run_id -n)
run_dir=/run/user/$run_id
run_home=/home/$run_as
term=xterm-256color

rel_date=$(date -d "$(date)" +%m-%d-%Y)
repo=$(cat .identity | grep REPO= | cut -d'=' -f2)
module=$(cat .identity | grep MODULE= | cut -d'=' -f2)
arm64_ver=$(cat .pinned_ver | grep arm64_ver= | cut -d'=' -f2)
amd64_ver=$(cat .pinned_ver | grep amd64_ver= | cut -d'=' -f2)
export -- HOME=$run_home TERM=$term PATH=/bin:/sbin:/snap/bin TRIPL=$repo/$module:$rel_date

if [[ "$run_id" == "" ]]; then
  if [[ "$(whoami)" == *root* ]]; then
    echo -e "\nDO NOT run with escalated priviledges!\nScript will Use: ~\$ 'pkexec --keep-cwd $0 $PRESERVED'\n" && exit 1
  else
    echo -e "\nPkexec is required for installation steps\nUsing: ~\$ 'pkexec --keep-cwd $0 --runme $(id -u) $PRESERVED'\n"
    argv_run="exec pkexec --keep-cwd '$0' --runme $(id -u) $PRESERVED"
    if [[ "$(which asciinema)" != "" ]]; then
      mkdir -p $HOME/.casts/$repo && exec asciinema rec --overwrite -i 3 -t "$TRIPL" $HOME/.casts/$TRIPL.cast -c "$argv_run"
    else
      $argv_run
    fi
  fi
fi

if [[ "$TEST" != *no* ]]; then
  touch $nulled $pushd_log
  chown root:root $nulled $pushd_log
  cat << __EOF
Cross Compile: $CROSS
Increment: $INC
Override Source Epoch: $EPOCH
Mount: /dev/$MOUNT
Push to Branch: $BRANCH
Tag Release: $TAG
Run Tests: $TESTS2 - $TEST - $TESTS
Run Level: $RUNME
__EOF
fi

if [[ "$(uname -m)" == "aarch64" ]]; then
  docker_snap_ver=$arm64_ver
  uname=aarch64; aname=arm64; ANAME=$aname
elif [[ "$(uname -m)" == "x86_64" ]]; then
  docker_snap_ver=$amd64_ver
  uname=x86_64; aname=amd64; ANAME=$aname
else
  echo 'Unknown Architecture '$(uname -m) && exit 1
fi

RUN_DIR=$run_dir; RESULTS=results
home=$HOME; path=$PATH; results=$RESULTS
pushd_results="pushd $RESULTS >> $pushd_log"
popd="popd -- >> $pushd_log"
NO_AI="$(sed -n 2p $0)"
local_data=$home/.local
local_bin=$home/docker/bin
local_lib=$home/docker/lib
data_dir=$local_data/share
rootless_path=$data_dir/rootless
sc_rules=/lib/udev/rules.d/60-scdaemon.rules
sysusr_path=$data_dir/systemd/user
sysusr_service=$sysusr_path/docker.dockerd.service
systemd_path=/etc/systemd/system
systemd_service=$systemd_path/snap.docker.dockerd.service
plugins_path=usr/libexec/docker/cli-plugins
var_docker=/var/snap/docker
OCI=org.opencontainers.image
snap_path=snap/docker/$docker_snap_ver
docker_plugins=/$plugins_path/docker-
docker_data=$data_dir/docker
docker_path=/$snap_path/bin
docker=$docker_path/docker
dockerd=${docker}d

sed_ech=$(cat << ___EOF
\\\\[Service\\\\]\\
Type=exec\\
Group=$run_as\\
ExitType=cgroup\\
Slice=docker.slice\\
Delegate=cpu\\ cpuset\\ io\\ memory\\ pids\\
___EOF
)

clean_most() {
  rm -r -f /home/root/*
  rm -r -f /root/snap/docker/
  rm -r -f $docker_data*
  rm -r -f $var_docker/common/*
  rm -r -f $var_docker/$docker_snap_ver/*
  rm -r -f $run_dir/containerd/
  rm -r -f $run_dir/docker*
  rm -r -f $run_dir/runc/
  rm -r -f /run/containerd/
  rm -r -f /run/docker*
  rm -r -f /run/runc/
  rm -r -f /run/snap.docker/
}

clean_all() {
  rm -r -f $home/$snap_path/*
  rm -r -f $home/snap/docker/
  rm -r -f $home/docker/
  rm -r -f $home/.docker/
  rm -r -f $data_dir/rootless*
  rm -r -f $data_dir/systemd/
  clean_most || echo "Failed cleanup"
  rm -r -f $var_docker/
  rm -r -f /usr/libexec/docker/
  rm -r -f /var/lib/snapd/cache/*
}

unmount() {
  quiet snap disable docker && sleep 1
  if [[ -d $docker_data ]]; then
    lsofd=$(echo $(lsof -F p $docker_data 2>> $nulled || true) | cut -d'p' -f2)
    if [[ "$lsofd" -gt 0 ]]; then
      quiet kill $lsofd && rm -r -f $docker_data/* && sync
    fi
  fi
  quiet umount $docker_data && sleep 1
  quiet systemd-cryptsetup detach $module && sleep 1
  quiet dmsetup remove /dev/mapper/$module && sleep 1
  rm -r -f $docker_data/ && sync
}

systemd_ctl_common() {
  snap stop docker && wait
  systemctl daemon-reload && wait
  systemctl reset-failed && wait
  systemctl stop snap.docker.* --all && wait
}

quiet() {
  echt="$@"
  script -a -q -c "$echt" $nulled >> $nulled
}

if [[ "$MOUNT" != "" ]]; then
  unmount
fi

clean_all || echo "Failed cleanup"

apt-get -qq update && apt-get -qq upgrade -y && \
apt-get -qq install --no-install-recommends --purge --autoremove -u acl+ bc+ cosign+ dbus-user-session+ dosfstools+ gh+ git-lfs+ gnupg2+ \
                                                                    gpg-agent+ jq+ parted+ pass+ pinentry-curses+ pkexec+ rootlesskit+ \
                                                                    scdaemon+ slirp4netns+ snapd+ systemd-container+ \
                                                                    systemd-cryptsetup+ uidmap+ golang-docker-credential-helpers- \
                                                                    docker- docker.io- docker-ce- docker-ce-cli- || \
                                                                    echo "Failed apt install"
snap install syft --classic
snap install grype --classic
snap remove docker --purge 2>> $nulled && wait || echo "Failed to remove Docker"
snap install docker --revision=$docker_snap_ver || echo "Failed to install Docker"

snap set docker nvidia-support.disabled=true && \
echo -e "\nRemoving feature docker:nvidia-support\nRemoving feature docker:cdi" || \
echo "Failed to disable docker:nvidia-support"

for d in docker-daemon firewall-control network-bind network-control opengl privileged support; do
  snap disconnect docker:$d >> $nulled && echo "Removing plug docker:"$d || exit 1
done && unset d && sleep 1 && echo

systemd_ctl_common
quiet systemctl mask snap.docker.nvidia-container-toolkit --runtime --now
quiet systemctl mask snap.docker.dockerd --runtime --now
mkdir -p /home/root && sed -i.backup "s|:/root:|:/home/root:|" /etc/passwd
quiet networkctl delete docker0

clean_most || echo "Failed cleanup"
rm -f -r $docker_data/ && mkdir -p $docker_data && chown $run_as:$run_as $docker_data

mkdir -p /$plugins_path && wait
ln -f -s /$snap_path${docker_plugins}buildx ${docker_plugins}buildx >> $nulled || exit 1
ln -f -s /$snap_path${docker_plugins}compose ${docker_plugins}compose >> $nulled || exit 1

if [[ "$SKIP_LOGIN" == "" ]]; then
  if [[ "$(cat $sc_rules | grep $run_as)" != *$run_as* ]]; then
    sed -i.backup "s/\"1050\", ATTR{idProduct}==\"040.\", /&MODE=\"0660\", GROUP=\"$run_as\", /g" $sc_rules
    udevadm control --reload-rules && udevadm trigger
  fi
  
  while [[ "$(lsusb -d 1050: | grep Yubikey)" != *Yubikey* ]]; do
    printf "\r🔐 Please insert yubikey - (CCID)\033[K"
  done && sleep 1 && echo

  quiet chown $run_as:$run_as /dev/hidraw*
  BUS=$(lsusb -d 1050: | grep -o Bus.... - | grep -o [0-9][0-9][0-9])
  DEVICE=$(lsusb -d 1050: | grep -o Device.... - | grep -o [0-9][0-9][0-9])
  set_facl="setfacl -m u:$run_as:rw /dev/bus/usb/$BUS/$DEVICE"
  quiet $set_facl || quiet $set_facl || exit 1
fi

if [[ "$MOUNT" != "" ]]; then
  systemd-cryptsetup attach $module /dev/$MOUNT && sleep 1 && echo
  mount /dev/mapper/$module $docker_data && sleep 1
  rm -f -r $docker_data/* && chown $run_as:$run_as $docker_data
fi
if [[ "$TEST" != *no* ]]; then
  chown $run_as:$run_as $nulled $pushd_log
  rootless_path=$home/rootless
  debug_cat="journalctl -o cat -t USR_RNLVL -f"
  systemd_cat="systemd-cat -t USR_RNLVL -p debug"
else
  push="--push"
  declare -- PUSH="$push"
fi
if [[ "$CROSS" == "yes" ]]; then
  DOUBLE="--platform linux/arm64,linux/amd64"
  declare -- CROSS="$DOUBLE"
else
  SINGLE="--platform linux/$ANAME"
  declare -- CROSS="$SINGLE"
fi

pushd $docker_data >> $pushd_log
  snap version > snap.info
  snap debug execution snap >> snap.info
  snap debug execution apparmor >> snap.info
  snap debug sandbox-features >> snap.info
  save_id=0:0.env
  set > $save_id
  env | sort >> $save_id
  declare >> $save_id
  chown $run_as:$run_as $save_id snap.info
$popd

echo 'Running as user: '$run_as' - user_id:group_id '$run_id:$run_id
$debug_cat &
$systemd_cat machinectl shell $run_as@ /bin/env - /bin/bash --norc --noprofile -c "
$debug
cd $PWD

mkdir -p $home/.ssh && chmod 0700 $home/.ssh && \
touch $home/.ssh/config && chmod 0644 $home/.ssh/config || exit 1

export -- \
ANAME='$ANAME' BRANCH='$BRANCH' CROSS='$CROSS' DBUS_SESSION_BUS_ADDRESS='unix:path=$RUN_DIR/bus' EPOCH='$EPOCH' \
GPG_TTY='\$(/bin/tty)' HOME='$HOME' INC='$INC' MOUNT='$MOUNT' NO_AI='$NO_AI' OCI='$OCI' PATH='$PATH' POPD='$popd' \
PUSH='$PUSH' PUSHD_LOG='$pushd_log' PUSHD_RESULTS='$pushd_results' RESULTS='$RESULTS' SKIP_LOGIN='$SKIP_LOGIN' \
SSH_CONF='\$(<$HOME/.ssh/config)' TAG='$TAG' TERM='$TERM' TEST='$TEST' TESTS='$TESTS' TRIPL='$TRIPL' XDG_RUNTIME_DIR='$RUN_DIR' \
|| exit 1

eval \"\$(ssh-agent -s)\" >> $nulled && wait
systemctl --user restart gpg-agent.service && wait

source .identity && echo -e \"\n$PWD/.identity sourced\" || exit 1
source .pinned_ver && echo -e \"$PWD/.pinned_ver sourced\n\" || exit 1

marker() { # \$1 = name, \$2 = syft/grype, \$3 = sort/order, \$4 = grep match
  unset \"wright\$3\"
  grep \"\$4\" \$1.\$2.tmp | tail -n 1 > \$1.\$2.status.\$3
  line=\$(cat \$1.\$2.status.\$3)
  if [[ \"\$line\" == *\$4* ]]; then
    export -- \"wright\$3\"=\"\$line\"
  fi
}

wright() { # \$1 = name, \$2 = syft/grype
  echo \$wright1 > \$1.\$2.status
  echo \$wright2 >> \$1.\$2.status
  echo \$wright3 >> \$1.\$2.status
  if [[ \"\$2\" == \"syft\" ]]; then
    echo \$wright4 >> \$1.\$2.status
    echo \$wright5 >> \$1.\$2.status
  fi
  sed -i 's/[^[:print:]]//g' \$1.\$2.status
  sed -i 's/\[K//g' \$1.\$2.status
  sed -i 's/\[2A//g' \$1.\$2.status
  sed -i 's/\[3A//g' \$1.\$2.status
  rm -f \$1.\$2.tmp*
  rm -f \$1.\$2.status.*
}

gryped() { # \$1 = name
  marker \$1 grype 1 \"✔ Scanned for vulnerabilities\"
  marker \$1 grype 2 \"├── by severity:\"
  marker \$1 grype 3 \"└── by status:\"
  wright \$1 grype
}

syfted() { # \$1 = name
  marker \$1 syft 1 \"✔ Cataloged contents\"
  marker \$1 syft 2 \"├── ✔ Packages\"
  marker \$1 syft 3 \"├── ✔ Executables\"
  marker \$1 syft 4 \"├── ✔ File metadata\"
  marker \$1 syft 5 \"└── ✔ File digests\"
  wright \$1 syft
}

attest_multi-arch() { # \$1 = name, \$2 = repo/name:tag, \$3 = \$cross (--platform linux/amd64,linux/arm64)
  if [[ \"\$SKIP_LOGIN\" == \"\" ]]; then
    src_att=\"--source-name \$1 --source-supplier \$USERNAME --source-version \$(date +%s)\"
    read -p \"🔐 Press enter to start attestation for \$2 \$3\"
    echo -e '\nStarting Syft...\n' && touch .pager1 && tail -f .pager1 & pid1=\$!
    syft_att_run=\"script -q -c 'TMPDIR=$docker_data/syft syft attest --output spdx-json docker.io/\$2 \
    \$3 \$src_att' /dev/null > .pager1\"
    quiet \$syft_att_run || quiet \$syft_att_run || exit 1
    kill \$pid1 && rm -f .pager1 && echo || exit 1
    
    sleep 5 && echo docker.io/\$2@\$(cat \$1.image.id) > \$1.index.ref
    docker buildx imagetools inspect --format {{ json .Provenance }} \$(cat \$1.index.ref) > \$1.provenance.json
    docker buildx imagetools inspect --format {{ .Manifest }} \$(cat \$1.index.ref) > \$1.manifest.md
    jsin=\$(docker buildx imagetools inspect --format {{ json . }} \$(cat \$1.index.ref))
    
    digest1=\$(echo \$jsin | jq .manifest.manifests.[0].digest | cut -d'\"' -f2)
    arr1=\$(echo \$jsin | jq .manifest.manifests.[0].platform.architecture | cut -d'\"' -f2)
    att1=\$(echo \$(echo \$jsin | jq .manifest.manifests.[2].annotations.[] | cut -d'\"' -f2 ) | cut -d' ' -f1)
    digest2=\$(echo \$jsin | jq .manifest.manifests.[1].digest | cut -d'\"' -f2)
    arr2=\$(echo \$jsin | jq .manifest.manifests.[1].platform.architecture | cut -d'\"' -f2)
    att2=\$(echo \$(echo \$jsin | jq .manifest.manifests.[3].annotations.[] | cut -d'\"' -f2 ) | cut -d' ' -f1)
    
    if [[ \"\$digest1\" == \"\$att1\" ]]; then
      echo docker.io/\$2@\$digest1 > \$arr1/\$1.manifest.ref
    fi
    if [[ \"\$digest2\" == \"\$att2\" ]]; then
      echo docker.io/\$2@\$digest2 > \$arr2/\$1.manifest.ref
    fi
    
    for arr in \$arr1 \$arr2; do
      echo 'Starting Cosign...' && pushd \$arr >> $pushd_log
      cosign_run=\"script -q -c 'cosign verify-attestation \$(cat \$1.manifest.ref) \
        --certificate-oidc-issuer https://github.com/login/oauth \
        --certificate-identity \$SIGSTORE_USR --type spdxjson \
        > \$1.sig.bundle' /dev/null > \$1.attested\"
      quiet \$cosign_run || quiet \$cosign_run || exit 1
      cat \$1.attested && $popd
    done && unset arr
  else
    echo 'Skipping Attestations: Docker Hub: not logged in...'
  fi
}

scan_using_grype() { # \$1 = name, \$2 = repo/name:tag or '/path --select-catalogers directory', \$3 = platform(amd64 or arm64)
  if [[ \"\$SKIP_LOGIN\" == \"\" ]]; then
    src=\"--source-name \$1 --source-supplier \$USERNAME --source-version \$(date +%s)\"
    if [[ \"\$3\" != \"\" ]]; then
      pushd \$3 >> $pushd_log
      arch=--platform\ linux/\$3
      R=\"\$2 - \$3\" 
    else
      pushd . >> $pushd_log
      unset arch
      R=\"\$1\"
    fi
    echo -e '\nStarting Syft...\n'
    touch \$1.syft.tmp && tail -f \$1.syft.tmp & pid2=\$!
    syft_run=\"script -q -c 'TMPDIR=$docker_data/syft syft scan \$2 \$src \$arch -o spdx-json=\$1.spdx.json' /dev/null > \$1.syft.tmp\"
    quiet \$syft_run || quiet \$syft_run || exit 1
    kill \$pid2 && rm -f -r $docker_data/syft/* && echo && syfted \$1 || exit 1
    echo \$R' - Syft Scan Results - '\$(syft --version) > \$1.contents
  	cat \$1.syft.status >> \$1.contents && rm -f \$1.syft.status
    
    echo -e 'Starting Grype...\n' && grype config > $docker_data/.grype.yaml
    touch \$1.grype.tmp && tail -f \$1.grype.tmp & pid3=\$!
    script -q -c \"TMPDIR=$docker_data/grype grype sbom:\$1.spdx.json \
    -c $docker_data/.grype.yaml \$arch -o json --file \$1.grype.json\" /dev/null > \$1.grype.tmp
    kill \$pid3 && rm -f -r $docker_data/grype/* && echo && gryped \$1 || exit 1
  	echo \$R' - Grype Scan Results - '\$(grype --version) > \$1.vulns
  	cat \$1.grype.status >> \$1.vulns && rm -f \$1.grype.status
  $popd
  else
    echo 'Skipping Syft and Grype: Docker Hub: not logged in...'
  fi
}

ssh_config() {
  if [[ \"\$SSH_CONF\" != *\$MODULE* ]]; then
    echo \"
Host \$MODULE
  Hostname github.com
  IdentityFile $home/\$IDENTITY_FILE
  IdentitiesOnly yes\" >> $home/.ssh/config
  fi
  if [[ \"\$SSH_CONF\" != *.pki* ]]; then
    echo \"
Host .pki
  Hostname github.com
  IdentityFile $home/\$PKI_ID_FILE
  IdentitiesOnly yes\" >> $home/.ssh/config
  fi
}

drop_down() {
  set +x; set +v; read -p 'Press enter to drop-down to the Rootless-Docker debug shell.'
  /bin/env - /bin/bash --noprofile --rcfile <(echo cd $PWD; export -- HOME=$HOME PATH=\$PATH TERM=$TERM; \
  echo source .identity; echo source .pinned_ver; echo source $rootless_path/tmp/env-rootless.exp; \
  echo 'docker() { echd=\"\$@\"; $docker \$echd; }'; echo \"echo -e '\nDropped down to interactive shell. \
  Type exit when done, or press ctrl+d'; PS1='    $run_as@docker:~\$'; \
  PROMPT_COMMAND='echo -e \\\\\\\\nRootless~Docker:'; BUILDKIT_PROGRESS=plain;\"); set -xv;
}

clean_some() {
  rm -r -f $home/docker/
  rm -r -f $home/.docker/
  rm -r -f $data_dir/rootless*
  rm -r -f $data_dir/systemd/
}

sys_ctl_common() {
  systemctl --user daemon-reload && wait
  systemctl --user reset-failed && wait
  systemctl --user stop docker* --all && wait
  grep 0 <(systemctl --user list-units docker* --all --no-pager) || exit 1
}

subver() {
  sub_ver=\$1
  rel_date=\$(date -d \"\$(date)\" +\"%m-%d-%Y-00\$sub_ver\")
  date_rel=\$(date -d \"\$(date)\" +\"%Y-%m-%d-00\$sub_ver\")
  echo -e \"Build Subversion: 00\$sub_ver\n\" 
}

validate.with.pki() { # \$1 = full_url.TDL/.../[file]
  ./.pki/local.sh \$1 \$DEVICEFLOW_AUTH || exit 1
}

docker() {
  echd=\"\$@\"
  $docker \$echd
}

quiet() {
  echq=\"\$@\"
  script -a -q -c \"\$echq\" $nulled >> $nulled
}

confirm() { # \$1 = subject
  read -p \"Press enter then 👆 please confirm presence on security token for \$1.\"
}

clean_some || echo \"Failed cleanup\"

if [[ \"\$SKIP_LOGIN\" == \"\" ]]; then
  gpg2 --quick-set-ownertrust \$USER_ID ultimate || exit 1
  chmod 0600 $home/\$IDENTITY_FILE && chmod 0644 $home/\$IDENTITY_FILE.pub && \
  chmod 0600 $home/\$PKI_ID_FILE && chmod 0644 $home/\$PKI_ID_FILE.pub || exit 1
  ssh_config && ssh -T git@github.com 2>> $nulled || true
  ssh-add -t 1D -h git@github.com $home/\$IDENTITY_FILE && \
  ssh-add -t 1D -h git@github.com $home/\$PKI_ID_FILE && \
  echo && ssh-add -l && echo || exit 1
  
  git remote remove origin && git remote add origin git@\$MODULE:\$REPO/\$PROJECT.git
  git-lfs install && git reset --hard && git clean -xfd
  
  confirm 'git fetch - git@ssh (twice)' && echo 'Starting Git fetch...'
  git fetch --unshallow 2>> $nulled || true
  confirm 'git pull - git@ssh' && echo 'Starting Git pull...'
  git pull \$(git remote -v | awk '{ print \$2 }' | tail -n 1) \$(git rev-parse --abbrev-ref HEAD)
  
  echo && confirm 'git submodules - git@ssh (twice)' && echo 'Starting Git submodules...'
  if [[ ! -d ".pki" ]]; then
    mkdir -p .pki && git submodule add git@.pki:\$REPO/.pki.git
  else
    git submodule --quiet foreach \"cd .. && git config submodule.\$name.url git@\$name:\$REPO/\$name.git\"
  fi
  git submodule update --init --remote --merge
  
  if [[ \"\$(gpg-card list - openpgp)\" == *\$SIGNING_KEY* ]]; then
    echo -e '\nSigning key present' && mkdir -p $home/.password-store $home/$snap_path/ && pass init \$SIGNING_KEY && echo && \
    printf 'pass is initialized\npass is initialized\n' | pass insert docker-credential-helpers/docker-pass-initialized-check >> $nulled || exit 1
    mv -T $home/.password-store $home/$snap_path/.password-store || exit 1
    mv -T $home/.gnupg $home/$snap_path/.gnupg || exit 1
  else
    echo && echo \"Signing key \$SIGNING_KEY missing\"
    echo -e '\nCheck Yubikey and .identity file\n'
    lsusb && ls -la /dev/hid* && gpg-card list - openpgp
    systemctl --user status gpg-agent* --all --no-pager
    ls -la $home/.gnupg $home/.password-store
    exit 1
  fi
fi

source_date_epoch=1
if [[ \"\$EPOCH\" = *today* ]]; then
  timestamp=\$(date -d \$(date +%D) +%s);
  if [[ \"\$timestamp\" != \"\" ]]; then
    echo \"Setting SOURCE_DATE_EPOCH from today's date: \$(date +%D) = @\$timestamp\";
    source_date_epoch=\$((timestamp));
  else
    echo \"Can't get timestamp. Defaulting to 1.\";
    source_date_epoch=1;
  fi
elif [[ \"\$EPOCH\" != 0 ]]; then
  echo \"Using override timestamp \$EPOCH for SOURCE_DATE_EPOCH.\"
  source_date_epoch=\$((\$EPOCH))
else
  timestamp=\$(cat $results/release.sha512sum | grep Epoch | cut -d ' ' -f5)
  if [[ \"\$timestamp\" != \"\" ]]; then
    echo \"Setting SOURCE_DATE_EPOCH from release.sha512sum: \$(cat $results/release.sha512sum | grep Epoch | cut -d ' ' -f5)\"
    source_date_epoch=\$((timestamp))
    check_file=1
    cp $results/release.sha512sum /tmp/release.last.sha512sum
  else
    echo \"Can't get latest commit timestamp. Defaulting to 1.\"
    source_date_epoch=1
  fi
fi

unset rel_date date_rel rel_ver sub_ver
rel_date=\$(date -d \"\$(date)\" +\"%m-%d-%Y\")
date_rel=\$(date -d \"\$(date)\" +\"%Y-%m-%d\")
rel_ver=\$(git log --pretty=reference --grep=Successful\\ Build\\ of\\ Release\\ \$date_rel | wc -l)
sub_ver=\$(git submodule --quiet foreach \"git log --pretty=reference --grep=\$rel_date\" | wc -l)

export -- SOURCE_DATE_EPOCH=\$source_date_epoch SDE=\$source_date_epoch \
source_date_epoch=\$source_date_epoch sde=\$source_date_epoch
echo -e \"Setting rel_date from today's date: \$rel_date\n\"

rm -r -f Results* $results* && mkdir -p $results/{arm64,amd64,source,env} || exit 1
mkdir -p $docker_data/{syft,grype,tmp} $local_bin $local_lib/$uname-$OSTYPE $rootless_path/tmp $sysusr_path || exit 1
touch $rootless_path/{env-{docker,rootless},tmp/env-rootless.exp} && > $rootless_path.sh && chmod +x $rootless_path.sh || exit 1

cat >> $rootless_path.sh << ____EOF
#!/bin/env -S - /bin/bash --norc --noprofile
$debug && export -- HOME=$home PATH=$path TERM=$term
mkdir -p $rootless_path/tmp && wait && > $rootless_path/env-docker
> $rootless_path/env-rootless && > $rootless_path/tmp/env-rootless.exp && wait
XDG_SID=$(echo \$XDG_SESSION_ID)
XSID=$(echo /sys/fs/cgroup/user.slice/user-$run_id.slice/session-\$XDG_SID.scope/slirp4)
eval $(mkdir -p \$XSID) >> $nulled
rootlesskit --net=slirp4netns --copy-up=/etc --copy-up=/run --copy-up=/sys/fs/cgroup --disable-host-loopback \
--ipv6 --cgroupns --pidns --slirp4netns-sandbox=true --slirp4netns-seccomp=true --evacuate-cgroup2=slirp4 \
--state-dir=$rootless_path/tmp /bin/env -- /bin/bash --norc --rcfile <(echo set -m) --noprofile -i -c '
env > $rootless_path/env-docker && grep ROOTLESS $rootless_path/env-docker > $rootless_path/env-rootless

echo \"BUILDKIT_MULTI_PLATFORM=true
BUILDKIT_PROGRESS=tty
BUILDKIT_TTY_LOG_LINES=$(($LINES - 15))
BUILDX_GIT_LABELS=full
BUILDX_METADATA_PROVENANCE=max
BUILDX_METADATA_WARNINGS=1
DBUS_SESSION_BUS_ADDRESS=unix:path=$run_dir/bus
DOCKER_CONFIG=$home/docker
DOCKER_HOST=unix://$run_dir/docker.sock
DOCKER_TMPDIR=$docker_data/tmp
GRYPE_DB_CACHE_DIR=$docker_data/grype
HOME=$home
NO_COLOR=true
PATH=$path:$docker_path:$home/docker/bin
SOURCE_DATE_EPOCH=\$sde
SYFT_CACHE_DIR=$docker_data/syft
TERM=$term
XDG_CONFIG_HOME=$home
XDG_RUNTIME_DIR=$run_dir\" >> $rootless_path/env-rootless

sed \"s/^/export -- /g\" $rootless_path/env-rootless > $rootless_path/tmp/env-rootless.exp
\$(echo \"echo echo $\(\<$rootless_path/env-rootless\)\" $dockerd --rootless \
--userland-proxy-path $docker_path/docker-proxy --init-path $docker_path/docker-init --init \
--feature cdi=false --cgroup-parent docker.slice --group $run_as --data-root $docker_data \
--exec-root $run_dir/docker --pidfile $run_dir/docker.pid) | /bin/bash --norc --noprofile | \
/bin/bash --norc --noprofile 2>> $rootless_path/rootless.log' 2>> $rootless_path/rootlesskit.log
rm -f $rootless_path/env-*
____EOF

cp $systemd_service $sysusr_service && wait && \
sed -z -i \"s|\[Service\]\nEnv|$(printf \"%s\\\\n\" $(echo $sed_ech))Env|\" $sysusr_service && \
sed -i \"s|EnvironmentFile.*|EnvironmentFile=-$rootless_path/env-rootless|\" $sysusr_service && \
sed -i \"s|ExecStart.*|ExecStart=/bin/env - /bin/bash -c \'$rootless_path.sh\'|\" $sysusr_service || exit 1

sys_ctl_common && systemctl --user start docker.dockerd && sleep 5
systemctl --user status docker.slice --all --no-pager -l > $rootless_path/docker.slice.log
systemctl --user status docker.dockerd --all --no-pager -l > $rootless_path/docker.dockerd.log
source $rootless_path/tmp/env-rootless.exp && echo \"$rootless_path/tmp/env-rootless.exp sourced\" || exit 1
quiet \"$docker info | grep rootless > $rootless_path/tmp/rootless.status\"

if [[ \"\$(grep root $rootless_path/tmp/rootless.status)\" != *rootless* ]]; then
  echo -e 'Rootless Docker Failed\n' && exit 1
else
  rootless='Rootless Docker Started\n'
  echo -e \$rootless
  echo -e \$rootless > $rootless_path/tmp/rootless.status
fi

$pushd_results && pushd env >> $pushd_log
  save_id=$run_id:$run_id.env
  set > \$save_id
  env | sort >> \$save_id
  declare >> \$save_id
  mv $docker_data/{0:0.env,snap.info} .
  cp $rootless_path/env-docker docker.env
  echo -e '\nDocker Version:\n' >> docker.info
  quiet '$docker version > docker.info'
  echo -e '\nDocker Info:\n' >> docker.info
  quiet '$docker info >> docker.info'
  echo -e '\nBuildx Version:\n' >> docker.info
  quiet '$docker buildx version >> docker.info'
  echo -e '\nBuildx Inspect:\n' >> docker.info
  quiet '$docker buildx inspect --bootstrap >> docker.info'
$popd && $popd

if [[ \"\$SKIP_LOGIN\" == \"\" ]]; then
  if [[ \"\$(which docker-credential-pass)\" == \"\" ]]; then
    validate.with.pki \"\$cred_helper\" || exit 1
    echo \"\$cred_helper_sha  \$cred_helper_name\" | sha512sum -c || exit 1
    mv \$cred_helper_name $local_bin/docker-credential-pass && \
    chmod +x $local_bin/docker-credential-pass || exit 1
  else
    cp \$(which docker-credential-pass) $local_bin/docker-credential-pass || exit 1
  fi
  echo '{
  \"credsStore\": \"pass\"
}' > $home/docker/config.json
  echo Installed at: $local_bin/docker-credential-pass && \
  cp \$(which pass) $local_bin/pass && \
  echo Installed at: $local_bin/pass && \
  cp \$(which gpg) $local_bin/gpg && \
  echo Installed at: $local_bin/gpg && \
  cp /lib/$uname-$OSTYPE/libassuan.so.9* $local_lib/$uname-$OSTYPE/ && \
  echo Installed at: $local_lib/$uname-$OSTYPE/libassuan.so.9 || exit 1
  credstat='docker-credential-pass list'
  echo && read -p '🔐 Press enter to start docker login.'
  snap run --shell docker.docker -c 'PATH=\$PATH:$local_bin ; \
  LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:$local_lib/:$local_lib/$uname-$OSTYPE ; docker login' || exit 1
  mv -T $home/$snap_path/.password-store $home/.password-store || exit 1
  mv -T $home/$snap_path/.gnupg $home/.gnupg && echo Credentials: \$(\$credstat) || exit 1
  syft login registry-1.docker.io -u \$USERNAME && echo -e '\nLogged in to syft\n' || exit 1
fi

if [[ \"\$CROSS\" != *no* ]]; then
  if [[ \"\$(uname -m)\" == \"aarch64\" ]]; then
    docker run --privileged --cgroupns private --rm \$binfmt_arm64 --install amd64
  elif [[ \"\$(uname -m)\" == \"x86_64\" ]]; then
    docker run --privileged --cgroupns private --rm \$binfmt_amd64 --install arm64
  else
    echo 'Unknown Architecture '\$(uname -m) && exit 1
  fi
  echo
fi

if [[ \"\$rel_ver\" -lt 1 ]]; then
  wait
elif [[ \"\$sub_ver\" -ge 1 ]]; then
  subver \$sub_ver
else
  sub_ver=1
  subver \$sub_ver
fi

if [[ \"\$SKIP_LOGIN\" == \"\" ]]; then
  source modules || drop_down || exit \$PIPESTATUS
else
  drop_down || exit \$PIPESTATUS
fi

$pushd_results
  scan_using_grype ubuntu \"/ --select-catalogers directory\"
  touch readme.md && cat */*.vulns >> readme.md && cat *.vulns >> readme.md
  sed -i 's/^/#### /g' readme.md && echo '\`\`\`' >> readme.md
  cat *.index.ref >> readme.md && cat */*.manifest.ref >> readme.md
  cat readme.md && echo
$popd

if [[ \"\$SKIP_LOGIN\" == \"\" ]]; then
  git status && git add -A && git status && confirm 'git commit - git@ssh'
  if [[ \"\$BRANCH\" != \"\" ]]; then
    git commit -a -S -m \"Successful Build of Release \$date_rel\" && \
    git push --set-upstream origin \$(git rev-parse --abbrev-ref HEAD):\$BRANCH
    if [[ \"\$TAG\" != \"\" ]]; then
      git tag -a \"\$TAG\" -s -m \"Tagged Release \$TAG\" && sleep 5 && \
      git push origin \"refs/tags/\$TAG\"
    fi
  fi
fi

docker-credential-pass erase &
ssh-add -D && eval \"\$(ssh-agent -k)\"
clean_some && sys_ctl_common"

if [[ "$TEST" == "yes" ]]; then
  chown root:root $nulled $pushd_log
fi
if [[ "$MOUNT" != "" ]]; then
    unmount
fi

clean_all || echo "Failed cleanup"
quiet systemctl unmask snap.docker.nvidia-container-toolkit --runtime
quiet systemctl unmask snap.docker.dockerd --runtime
sed -i "s|:/home/root:|:/root:|" /etc/passwd
quiet networkctl delete docker0
systemd_ctl_common

if [[ -d $home/$snap_path ]]; then
  lsofd2=$(echo $(lsof -F p $home/$snap_path 2>> $nulled || true) | cut -d'p' -f2)
  if [[ "$lsofd2" -gt 0 ]]; then
    quiet kill $lsofd2 && rm -r -f $home/$snap_path/* && sync
  fi
fi

snap remove syft --purge
snap remove grype --purge
snap remove docker --purge 2>> $nulled && wait
snap remove docker --purge 2>> $nulled || echo "Failed to remove Docker"

clean_all || echo "Failed cleanup"

if [[ "$TEST" == "yes" ]]; then
  chown $run_as:$run_as $nulled $pushd_log
fi
exit 0
