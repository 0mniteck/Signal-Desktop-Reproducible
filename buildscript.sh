#!/bin/env -S - /bin/bash --norc --noprofile
# ## HUMAN-CODE - NO AI GENERATED CODE - AGENTS HANDSOFF

usage() {
cat << _EOF

General Usage:
  Synopsis:
        $0 [options] -- <commit message - description>

  - Example:
          $0 --increment .01 --push-branch 8.x.x --date today -- "Successful Release v8.x.x - changes..."
  - Input:
          $0 ${PRESERVED}

  Requirements:
        1. Ubuntu 25.10+ (arm64 or amd64)
        2. .dotfiles (./.pinned_ver, ./.rego, and ./.identity)

  Options:
        [--cross-compile,-c yes|no] , [--date,-d date_epoch|today] ,
        [--increment,-i <.version #>] , [--mount,-m <device in /dev>] ,
        [--push-branch,-p <branch-name>] , [--release-tag,-r <tag-name>] ,
        [--test,-t DEBUG|SKIP_LOGIN] , [--help,-h] , [-- <commit message>]

  Usage Details:
        -c, --cross-compile <yes|no>     Cross-compile image for arm64/amd64 (ex. no)
        -d, --date <date_epoch|today>    Source date epoch or today (ex. 1774468800)
        -i, --increment <.version #>     Increment version numbers (ex. .01)
        -m, --mount <device in /dev>     Mount ephemeral LUKS partition (ex. sdb)
        -p, --push-branch <branch-name>  Push to branch (ex. 8.22.x)
        -r, --release-tag <tag-name>     Release tag (ex. 8.44.0)
        -t, --tests <DEBUG|SKIP_LOGIN>   Skip Docker/Github login (ex. SKIP_LOGIN)
        -h, --help                       Show this usage file
        - , -- <commit message - desc>   Commit message (ex. "8.x Success! - changes...")

  Maintainers:
      - ID: @0mniteck (Shant) <shant@omniteck.com> https://0mniteck.com & https://omniteck.com
        - GPG/GIT: <10482171+0mniteck@users.noreply.github.com>
        - COSIGN/SIGSTORE: <tiger-varsity-alto@duck.com>
        - CONTACT/MAILTO: <shantt@duck.com>

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
SHORT="e:c:d:i:m:p:r:t:h"
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
     -|--)              COMMIT="$@"; continue ;;
     *|**)     echo $ERR >&2; usage;   exit 3 ;;
  esac
done

if [[ "$CROSS" == "" ]]; then declare -- CROSS="yes"; fi;
if [[ "$EPOCH" == "" ]]; then declare -- EPOCH=0; fi;

test() {
  nulled=/tmp/nulled.log
  pushd_log=/tmp/pushd.log
  if [[ "$RUNME" != "" ]]; then
    if [[ "$NO_CLEAN" == "" ]]; then rm -f $nulled $pushd_log /tmp/ch_id_*; fi;
    touch $nulled $pushd_log; > $nulled; > $pushd_log
  fi; declare -g -- nulled; declare -g -- pushd_log; usage
}

if [[ "$TEST" == "" || "$TEST" == *no* ]]; then
  debug="set -eo pipefail"
  nulled=/dev/null
  pushd_log=$nulled
  TEST="no"
elif [[ "$TEST" != *yes* ]]; then
  debug="set -vxeo pipefail"
  declare -- ${TEST}="yes"
  declare -- TESTS="${TEST}=${!TEST}"
  TEST="yes"
  test
else
  debug="echo"
  DEBUG="no"
  TESTS="DEBUG=no"
  TEST="yes"
  test
fi

$debug
run_id=$RUNME
run_as=$(id -u $run_id -n)
run_dir=/run/user/$run_id
run_home=/home/$run_as
term=xterm-256color

real_date=$(date +%m-%d-%Y)
repo=$(grep REPO= .identity | cut -d'=' -f2)
module=$(grep MODULE= .identity | cut -d'=' -f2)
arm64_ver=$(grep arm64_ver= .pinned_ver | cut -d'=' -f2)
amd64_ver=$(grep amd64_ver= .pinned_ver | cut -d'=' -f2)

cohorts=$(sed -n '/{"coh/,/"}}}/p' .pinned_ver | tr ' ' '\n' | sed -n '/{"coh/,/"}}}/p' | jq -c .[])
ch_docker=$(echo $cohorts | jq -r .docker[])
ch_syft=$(echo $cohorts | jq -r .syft[])
ch_grype=$(echo $cohorts | jq -r .grype[])

export -- HOME=$run_home \
TERM=$term PATH=/bin:/sbin:/snap/bin \
TRIPL=$repo/$module:$real_date
unset id; id=$(id -u)

if [[ "${run_id}" == "" ]]; then
  if [[ "$(whoami)" == *root* || "${id}" == "0" ]]; then
    echo -e "\nDO NOT run with escalated priviledges!\nScript will Use: ~\$ 'pkexec --keep-cwd $0 $PRESERVED'\n" && exit 1; else
    echo -e "\nPkexec is required for installation steps\nUsing: ~\$ 'pkexec --keep-cwd $0 -e ${id} $PRESERVED'\n"
    argv_run="exec pkexec --keep-cwd '$0' -e ${id} $PRESERVED"
    if [[ "$(which asciinema)" != "" ]]; then
      mkdir -p $HOME/.casts/$repo
      exec asciinema rec --overwrite -i 3 -t "$TRIPL" $HOME/.casts/$TRIPL.cast -c "$argv_run"; else $argv_run; fi;
fi; fi;

if [[ "$TEST" == *yes* ]]; then
cat << __EOF
Tag Release: $TAG
Commit Message: $COMMIT
Push to Branch: $BRANCH
Cross Compile: $CROSS
Override Date: $EPOCH
Increment: $INC
Mount: /dev/$MOUNT
Run Tests: TEST=$TEST - \
TESTS=$TESTS - $TESTS
Run Level: $RUNME
__EOF
fi

if [[ "$(uname -m)" == "aarch64" ]]; then docker_snap_ver=$arm64_ver; uname=aarch64; aname=arm64; ANAME=$aname;
elif [[ "$(uname -m)" == "x86_64" ]]; then docker_snap_ver=$amd64_ver; uname=x86_64; aname=amd64; ANAME=$aname; else
  echo 'Unknown Architecture '$(uname -m); exit 1; fi;

home=$HOME; path=$PATH; term=$TERM; results=results
pushd_results="pushd $results >> $pushd_log"
popd="popd -- >> $pushd_log"
POPD=$popd; RESULTS=$results
PUSHD_RESULTS=$pushd_results
PUSHD_LOG=$pushd_log; RUN_DIR=$run_dir
no_ai="$(sed -n 2p $0)"; NO_AI=$no_ai
oci=org.opencontainers.image; OCI=$oci

local_data=$home/.local
local_bin=$home/docker/bin
local_lib=$home/docker/lib
data_dir=$local_data/share
rootless_path=$data_dir/rootless
apparmor_path=/etc/apparmor.d
apparmor_profile=$apparmor_path/re-snapd.rootless.docker
cgroup_base=/sys/fs/cgroup/user.slice/user-${run_id}.slice
sc_rules=/lib/udev/rules.d/60-scdaemon.rules
sysusr_path=$data_dir/systemd/user
sysusr_service=$sysusr_path/docker.dockerd.service
systemd_path=/etc/systemd/system
systemd_service=$systemd_path/snap.docker_rootless.dockerd.service
plugins_path=usr/libexec/docker/cli-plugins
var_docker=/var/snap/docker
snap_path=snap/docker_rootless/$docker_snap_ver
docker_plugins=/$plugins_path/docker-
docker_data=$data_dir/docker
docker_path=/$snap_path/bin
docker=$docker_path/docker
dockerd=${docker}d

sed_ech=$(cat << ___EOF
AssertUser=$run_id\\
AssertGroup=$run_id\\
AllowIsolate=true\\
\\
\\\\[Service\\\\]\\
Group=$run_as\\
ExitType=cgroup\\
Slice=docker.slice\\
___EOF
)

clean_most() {
if [[ "$NO_CLEAN" == "" ]]; then
  rm -r -f /home/root/* \
  /root/snap/docker* \
  $docker_data* \
  $var_docker/common/* \
  $var_docker/$docker_snap_ver/* \
  $run_dir/containerd/ \
  $run_dir/docker* \
  $run_dir/runc/ \
  /run/containerd/ \
  /run/docker* \
  /run/runc/ \
  /run/snap.docker*; fi;
}

clean_all() {
if [[ "$NO_CLEAN" == "" ]]; then
  rm -r -f $home/$snap_path/* \
  /tmp/snap-private-tmp/snap.docker* \
  $home/snap/docker* \
  $home/docker/ \
  $home/.docker/ \
  $data_dir/rootless* \
  $data_dir/systemd/ \
  $var_docker* \
  /usr/libexec/docker/ \
  /var/lib/snapd/cache/*; fi;
  clean_most || echo "Failed clean_most"
}

unmount() {
  quiet snap stop --disable docker_rootless && sleep 1
  if [[ -d $docker_data ]]; then
    lsof_d="$(cat <(lsof -F p $docker_data | cut -d'p' -f2 || true))"
    for l in $lsof_d; do quiet kill $l; done; unset l
    if [[ "$NO_CLEAN" == "" ]]; then rm -r -f $docker_data/*; sync; fi; fi;
  quiet umount $docker_data && sleep 1
  quiet systemd-cryptsetup detach $module && sleep 1
  quiet dmsetup remove /dev/mapper/$module && sleep 1
  if [[ "$NO_CLEAN" == "" ]]; then rm -r -f $docker_data/; sync; fi;
}

systemd_ctl_common() { # $1 = mask/unmask, $2 = wait/sleep\ 1s, $3 = --now
  snap stop --disable docker_rootless.dockerd && $2
  snap stop --disable docker_rootless.nvidia-container-toolkit && $2
  systemctl daemon-reload && $2
  systemctl reset-failed && $2
  systemctl stop snap.docker_rootless.* --all && $2
  quiet systemctl $1 snap.docker_rootless.nvidia-container-toolkit --runtime $3
  quiet systemctl $1 snap.docker_rootless.dockerd --runtime $3
  quiet networkctl delete docker0
  quiet networkctl delete tun0
}
                 # $1 = snap to install, $2 = mode (--classic,--jailmode,--devmode,--dangerous), $3 = cohort_id,
snap_install() { # $4 = --unaliased (optional), $5 = --name=instance_name (optional)
  if [[ $(snap debug confinement) == *strict* ]]; then wait; else echo "Strict confinement required!" exit 1; fi;
  unset ch_id name version; name=$(echo $1 | cut -d'.' -f1); ch_id=$(snap install $1 $2 --cohort=$3 $4 $5 --no-wait);
  if [[ "$ch_id" -gt 0 ]]; then snap watch $ch_id; snap debug timings $ch_id > /tmp/snap_ch_id_$ch_id.change;
    if [[ $(snap list $name) ]]; then version="$(snap list $name | cut -d' ' -f3 | tr '\n' ' ' | cut -d'v' -f2)";
      if [[ "$5" == "" ]]; then wait; else version="$(echo $version | cut -d' ' -f2) "; fi;
      echo "${name} v${version}installed from cohort id \"$(echo $3 | sed -E "s/(.{$(($LINES/2))}).*/\1.../" )\"";
    else exit 1; fi;
  elif [[ $(snap list $name) ]]; then echo -e "\nsnap $name already installed!\nRemove then re-install to validate cohort!\n"; else
    echo "snap install $name: Failed!"; fi; unset ch_id name version;
}

# apparm() { # $1 = [-a/-r] [--add/--replace]
#   rm -f $apparmor_profile;
#   cp $apparmor_path/*snap-confine* $apparmor_profile
#   apparmor_parser $1 -K --abort-on-error --namespace-string docker $apparmor_profile }

quiet() {
  echt="$@"; script -a -q -c "$echt" $nulled >> $nulled
}

if [[ "$MOUNT" != "" ]]; then unmount; fi; clean_all || echo "Failed clean_all"
apt-get -qq update && apt-get -qq upgrade -y && \
apt-get -qq install --no-install-recommends --purge --autoremove -u acl+ bc+ cosign+ dbus-user-session+ dosfstools+ fuse-overlayfs+ gh+ git-lfs+ \
                                                                    gnupg2+ gpg-agent+ iptables+ jq+ parted+ pass+ pinentry-curses+ pkexec+ rootlesskit+ \
                                                                    scdaemon+ slirp4netns+ snapd+ systemd-container+ systemd-cryptsetup+ \
                                                                    uidmap+ golang-github*- golang-docker*- \
                                                                    docker- docker.io- docker-ce- docker-ce-cli- podman*- || \
                                                                    echo "Failed apt install"
if [[ "$NO_CLEAN" == "" ]]; then snap remove docker_rootless \
  --purge --terminate 2>> $nulled && wait || echo "Failed to remove Docker Rootless"; fi;
snap_install syft --classic $ch_syft || exit 1
snap_install grype --classic $ch_grype || exit 1

snap set system experimental.parallel-instances=true && \
printf '\rFetching snap "docker_rootless"\033[K' && \
snap download --basename=docker_rootless docker --cohort=$ch_docker >> $nulled && \
snap ack docker_rootless.assert || exit 1
snap_install docker_rootless.snap --jailmode $ch_docker --unaliased --name=docker_rootless || exit 1
if [[ "$NO_CLEAN" == "" ]]; then rm -f *.assert *.snap; fi;

snap set docker_rootless nvidia-support.runtime.config-override="" && \
snap set docker_rootless nvidia-support.disabled=true && echo && \
printf "\rRemoving feature docker_rootless:nvidia-support\033[K" && sleep 3 && \
printf "\rRemoving feature docker_rootless:cdi\033[K" && sleep 3 && \
printf "\rRemoved features: cdi, nvidia-support\033[K"\\n || \
echo "Failed to disable docker_rootless:nvidia-support"

plugs="docker-daemon firewall-control network-bind network-control opengl privileged support"
for plug in $plugs; do
  snap disconnect --forget docker_rootless:$plug >> $nulled && \
  printf "\rRemoving plug docker_rootless:$plug\033[K" || exit 1
done; sleep 1; printf "\rRemoved plugs: $(echo $plugs | sed 's/\ /,\ /g' )\033[K"\\n
unset plugs plug; echo; snap connections; echo

systemd_ctl_common mask wait --now || echo "Failed systemctl_common_mask"
mkdir -p /home/root && sed -i.backup "s|:/root:|:/home/root:|" /etc/passwd
clean_most || echo "Failed clean_most"

# if [[ -f $apparmor_profile ]]; then apparm -r; else apparm -a; fi;
echo 'options overlay metacopy=on' > /etc/modprobe.d/metacopy.conf
modprobe -a ip_tables overlay && wait && quiet 'echo Y | tee /sys/module/overlay/parameters/metacopy'
quiet 'sysctl -w kernel.unprivileged_userns_clone=1'

mkdir -p $docker_data /$plugins_path && chown $run_as:$run_as $docker_data && \
ln -f -s /$snap_path${docker_plugins}buildx ${docker_plugins}buildx >> $nulled || exit 1
ln -f -s /$snap_path${docker_plugins}compose ${docker_plugins}compose >> $nulled || exit 1

if [[ "$TESTS" != *SKIP_LOGIN* ]]; then
  if [[ "$(cat $sc_rules | grep $run_as)" != *$run_as* ]]; then
    sed -i.backup "s/\"1050\", ATTR{idProduct}==\"040.\", /&MODE=\"0660\", GROUP=\"$run_as\", /g" $sc_rules
    udevadm control --reload-rules && udevadm trigger; fi;
  while [[ "$(lsusb -d 1050: | grep Yubikey)" != *Yubikey* ]]; do
    printf "\r🔐 Please insert yubikey - (CCID)\033[K"; done; sleep 1; echo
  quiet chown $run_as:$run_as /dev/hidraw*
  BUS=$(lsusb -d 1050: | grep -o Bus.... - | grep -o [0-9][0-9][0-9])
  DEVICE=$(lsusb -d 1050: | grep -o Device.... - | grep -o [0-9][0-9][0-9])
  set_facl="setfacl -m u:$run_as:rw /dev/bus/usb/$BUS/$DEVICE"
  quiet $set_facl || quiet $set_facl || exit 1
fi

if [[ "$MOUNT" != "" ]]; then
  systemd-cryptsetup attach $module /dev/$MOUNT && sleep 1 && echo
  mount /dev/mapper/$module $docker_data && sleep 1
  if [[ "$NO_CLEAN" == "" ]]; then rm -f -r $docker_data/*; fi;
  chown $run_as:$run_as $docker_data
fi

pushd $docker_data >> $pushd_log
  if [[ "$DEBUG" == *yes* || "$NO_CLEAN" != "" ]]; then
    printf '\rSaving debugger info...\033[K'; unset debugger states state id save_id; > snap.info; > snap.install; > snap.events
    for debugger in \
{"version --verbose","debug "{{,sandbox-}features,"execution "{apparmor,snap},confinement,paths,snap-downloads-cache,seeding},"changes --abs-time","refresh --time"}; do
      echo "---------------snap-$debugger---------------" >> snap.info; quiet "snap $debugger >> snap.info"; done; unset debugger
    states=$(snap debug state --changes /var/lib/snapd/state.json | cut -w -f1 | sed 1d | tr '\n' ' ' )
    if [[ "$((${#states[0]}/2))" -ge 100 || "$DEBUG" == *no* ]]; then
      unset states; echo "Too many change ID's, start from a clean snapd install to run debugger"; fi;
    for state in $states; do
      echo "-------------debug-state-change-$state-------------" >> snap.events
      quiet "snap debug state --abs-time --change=$state /var/lib/snapd/state.json >> snap.events"
      echo "--------------debug-state-tasks-$state-------------" >> snap.events
      quiet "snap debug state --abs-time --task=$state /var/lib/snapd/state.json >> snap.events"
      echo "--------------------tasks-$state-------------------" >> snap.events
      quiet "snap tasks $state --abs-time >> snap.events"
      echo "------------debug-state-timings-$state-------------" >> snap.events
      quiet "snap debug timings $state >> snap.events"
    done; unset states state; printf '\rSaved debugger info\033[K'\\n\\n
    cat /tmp/snap_ch_id_* >> snap.install; rm -f /tmp/snap_ch_id_*
  fi; id=$(id -u); save_id=$id:$id.env
  set > $save_id; env | sort >> $save_id; declare >> $save_id
  chown --quiet $run_as:$run_as $save_id snap.{info,install,events} || true
popd -- >> $pushd_log; unset debugger states state id save_id

if [[ "$TEST" == *yes* ]]; then
  echo -e '\nRunning as user: '$run_as' - user_id:group_id '$run_id:$run_id'\n'
  chown $run_as:$run_as $nulled $pushd_log; export -- \
  SYSTEMD_LOG_LEVEL=debug NO_COLOR=true LESSSECURE=1 \
  SYSTEMD_LOG_COLOR=false SYSTEMD_COLORS=false \
  SYSTEMD_LOG_LOCATION=true SYSTEMD_LOG_TIME=true \
  SYSTEMD_LOG_TARGET=console SYSTEMD_URLIFY=false
  debug_cat="journalctl --output=cat --identifier=USR_RNLVL --follow"
  systemd_cat="systemd-cat --identifier=USR_RNLVL --priority=debug"
else push="--push"; declare -- PUSH="$push"; fi;

if [[ "$CROSS" == "yes" ]]; then
  DOUBLE="--platform linux/arm64,linux/amd64"; declare -- CROSS="$DOUBLE"; else
  SINGLE="--platform linux/$ANAME"; declare -- CROSS="$SINGLE"; fi;

wait1="while [[ -d $docker_data/ && ! -f $docker_data/xs.id ]]; do wait; done;"
wait2="if [[ -d $docker_data/ && -f $docker_data/xs.id ]]; then"
rem="rm -f $docker_data/xs.id"

eval $rem && wait
$(sleep 10; eval "$wait1 $wait2 mkdir -p $cgroup_base/session-$(cat $docker_data/xs.id).scope/slirp4; $rem; fi;") & mk_pid=$!
seen="$(cat <(find $cgroup_base -type d 2> /dev/null) | grep session-)"

$debug_cat & pid_0=$!
$systemd_cat machinectl shell $run_as@.host /bin/env - /bin/bash --norc --noprofile -c "
$debug && cd $PWD

mkdir -p $home/.ssh && chmod 0700 $home/.ssh && \
touch $home/.ssh/config && chmod 0644 $home/.ssh/config || exit 1

export -- ANAME='$ANAME' BRANCH='$BRANCH' CROSS='$CROSS' DBUS_SESSION_BUS_ADDRESS='unix:path=$RUN_DIR/bus' EPOCH='$EPOCH' \
GPG_TTY='\$(/bin/tty)' HOME='$HOME' INC='$INC' MOUNT='$MOUNT' NO_AI='$NO_AI' OCI='$OCI' PATH='$PATH' POPD='$POPD' \
PUSH='$PUSH' PUSHD_LOG='$PUSHD_LOG' PUSHD_RESULTS='$PUSHD_RESULTS' RESULTS='$RESULTS' SSH_CONF='\$(<$HOME/.ssh/config)' \
TAG='$TAG' TERM='$TERM' TEST='$TEST' TESTS='$TESTS' TRIPL='$TRIPL' XDG_RUNTIME_DIR='$RUN_DIR' || exit 1

seen1=\"$seen\"; seen2=\"\$(cat <(find $cgroup_base -type d 2> /dev/null) | grep session-)\"
seend=\"\$(echo \$(diff <(echo \$seen1 | tr ' ' '\n') <(echo \$seen2 | tr ' ' '\n') || true) | cut -d'>' -f2 | cut -d' ' -f2)\"
XDG_USR_SESSION=\"\$(echo \$seend | cut -d'-' -f3 | cut -d'.' -f1)\"
echo \$XDG_USR_SESSION > $docker_data/xs.id

while [[ -f $docker_data/xs.id || \$(cat <(lsof -F p -p $mk_pid -R | grep -o $mk_pid)) == *$mk_pid* ]]; do
  printf \\r$mk_pid': seen-daemon(seend) still running...\033[K'; sleep 5
done; sleep 1; mkdir -p \$seend/slirp4 && \
printf \"Session directory session-\$XDG_USR_SESSION.scope seen.\033[K\n\n\" || exit 1

eval \$(ssh-agent -s) >> $nulled && wait
systemctl --user restart gpg-agent.service && wait
source .identity && echo -e \"\n$PWD/.identity sourced\" || exit 1
source .pinned_ver && echo -e \"$PWD/.pinned_ver sourced\n\" || exit 1

marker() { # \$1 = name, \$2 = syft/grype, \$3 = sort/order, \$4 = grep match
  grep \"\$4\" \$1.\$2.tmp | tail -n 1 > \$1.\$2.status.\$3
  line=\$(cat \$1.\$2.status.\$3); unset \"wright\$3\"
  if [[ \"\$line\" == *\$4* ]]; then export -- \"wright\$3\"=\"\$line\"; fi;
}

wright() { # \$1 = name, \$2 = syft/grype
  echo \$wright1 > \$1.\$2.status; echo \$wright2 >> \$1.\$2.status; echo \$wright3 >> \$1.\$2.status
  if [[ \"\$2\" == \"syft\" ]]; then echo \$wright4 >> \$1.\$2.status; echo \$wright5 >> \$1.\$2.status; fi;
  sed -i 's/[^[:print:]]//g' \$1.\$2.status; sed -i 's/\[K//g' \$1.\$2.status; sed -i 's/\[2A//g' \$1.\$2.status
  sed -i 's/\[3A//g' \$1.\$2.status; if [[ \"$NO_CLEAN\" == \"\" ]]; then rm -f \$1.\$2.tmp*; rm -f \$1.\$2.status.*; fi;
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
  if [[ \"$TESTS\" != *SKIP_LOGIN* ]]; then src_att=\"--source-name \$1 --source-supplier \$USERNAME --source-version \$(date +%s)\";
    read -p \"🔐 Press enter to start attestation for \$2 \$3\"
    echo -e '\nStarting Syft...\n' && touch .pager1 && tail -f .pager1 & pid_1=\$!
    syft_att_run=\"script -q -c 'TMPDIR=$docker_data/syft syft attest --output spdx-json docker.io/\$2 \
    \$3 \$src_att' /dev/null > .pager1\"
    quiet \$syft_att_run || quiet \$syft_att_run || exit 1
    quiet kill \$pid_1 && rm -f .pager1 && echo || exit 1

    sleep 5 && echo docker.io/\$2@\$(cat \$1.image.id) > \$1.index.ref
    docker buildx imagetools inspect --format {{ json .Provenance.SLSA }} \$(cat \$1.index.ref) > \$1.provenance.json
    docker buildx imagetools inspect --format {{ .Manifest }} \$(cat \$1.index.ref) > \$1.manifest.md
    jsin=\$(docker buildx imagetools inspect --format {{ json . }} \$(cat \$1.index.ref))

    digest1=\$(echo \$jsin | jq .manifest.manifests.[0].digest | cut -d'\"' -f2)
    arr1=\$(echo \$jsin | jq .manifest.manifests.[0].platform.architecture | cut -d'\"' -f2)
    att1=\$(echo \$(echo \$jsin | jq .manifest.manifests.[2].annotations.[] | cut -d'\"' -f2 ) | cut -d' ' -f1)
    digest2=\$(echo \$jsin | jq .manifest.manifests.[1].digest | cut -d'\"' -f2)
    arr2=\$(echo \$jsin | jq .manifest.manifests.[1].platform.architecture | cut -d'\"' -f2)
    att2=\$(echo \$(echo \$jsin | jq .manifest.manifests.[3].annotations.[] | cut -d'\"' -f2 ) | cut -d' ' -f1)
    
    if [[ \"\$digest1\" == \"\$att1\" ]]; then echo docker.io/\$2@\$digest1 > \$arr1/\$1.manifest.ref; fi;
    if [[ \"\$digest2\" == \"\$att2\" ]]; then echo docker.io/\$2@\$digest2 > \$arr2/\$1.manifest.ref; fi;
    for arr in \$arr1 \$arr2; do echo 'Starting Cosign...'; pushd \$arr >> $pushd_log
      cosign_run=\"script -q -c 'cosign verify-attestation \$(cat \$1.manifest.ref) \
        --certificate-oidc-issuer https://github.com/login/oauth \
        --certificate-identity \$SIGSTORE_USR --type spdxjson \
        > \$1.sig.bundle' /dev/null > \$1.attested\"
      quiet \$cosign_run || quiet \$cosign_run || exit 1
      cat \$1.attested; \$POPD; done; unset arr; else
      echo 'Skipping Attestations: Docker Hub: not logged in...'; fi;
}

scan_using_grype() { # \$1 = name, \$2 = repo/name:tag or '/path --select-catalogers directory', \$3 = platform(amd64 or arm64)
  if [[ \"$TESTS\" != *SKIP_LOGIN* ]]; then src=\"--source-name \$1 --source-supplier \$USERNAME --source-version \$(date +%s)\";
    if [[ \"\$3\" != \"\" ]]; then pushd \$3 >> $pushd_log; arch=--platform\ linux/\$3; R=\"\$2 - \$3\"; else
      pushd . >> $pushd_log; unset arch; R=\"\$1\"; fi;

    echo -e '\nStarting Syft...\n'
    touch \$1.syft.tmp && tail -f \$1.syft.tmp & pid_2=\$!
    syft_run=\"script -q -c 'TMPDIR=$docker_data/syft syft scan \$2 \$src \$arch -o spdx-json=\$1.spdx.json' /dev/null > \$1.syft.tmp\"
    quiet \$syft_run || quiet \$syft_run || exit 1
    quiet kill \$pid_2 && rm -f -r $docker_data/syft/* && echo && syfted \$1 || exit 1
    echo \$R' - Syft Scan Results - '\$(syft --version) > \$1.contents
    cat \$1.syft.status >> \$1.contents && rm -f \$1.syft.status

    echo -e 'Starting Grype...\n' && grype config > $docker_data/.grype.yaml
    touch \$1.grype.tmp && tail -f \$1.grype.tmp & pid_3=\$!
    script -q -c \"TMPDIR=$docker_data/grype grype sbom:\$1.spdx.json \
    -c $docker_data/.grype.yaml \$arch -o json --file \$1.grype.json\" /dev/null > \$1.grype.tmp
    quiet kill \$pid_3 && rm -f -r $docker_data/grype/* && echo && gryped \$1 || exit 1
    echo \$R' - Grype Scan Results - '\$(grype --version) > \$1.vulns
    cat \$1.grype.status >> \$1.vulns && rm -f \$1.grype.status
    \$POPD; else echo 'Skipping Syft and Grype: Docker Hub: not logged in...'; fi;
}

ssh_config() {
  if [[ \"\$(echo \$(eval \$SSH_CONFIG) | grep -o $module)\" != *$module* ]]; then echo \"
Host \$MODULE
  Hostname github.com
  IdentityFile $home/\$IDENTITY_FILE
  IdentitiesOnly yes\" >> $home/.ssh/config; fi;
  if [[ \"\$(echo \$(eval \$SSH_CONFIG) | grep -o pki )\" != *pki* ]]; then echo \"
Host .pki
  Hostname github.com
  IdentityFile $home/\$PKI_ID_FILE
  IdentitiesOnly yes\" >> $home/.ssh/config; fi;
}

drop_down() {
  set +xv; read -p 'Press enter to drop-down to the Rootless-Docker debug shell.'
  /bin/env - /bin/bash --noprofile --rcfile <(echo cd $PWD; export -- HOME=$HOME PATH=\$PATH TERM=$TERM; \
  echo source .identity; echo source .pinned_ver; echo source $rootless_path/tmp/env-rootless.exp; \
  echo 'docker() { echd=\"\$@\"; $docker \$echd; }'; echo \"echo -e '\nDropped down to interactive shell. \
  Type exit when done, or press ctrl+d'; PS1='    $run_as@docker:~\$'; \
  PROMPT_COMMAND='echo -e \\\\\\\\nRootless~Docker:'; BUILDKIT_PROGRESS=plain;\"); $debug
}

sys_ctl_common() {
  systemctl --user daemon-reload && wait
  systemctl --user reset-failed && wait
  systemctl --user start dbus && wait
  systemctl --user stop docker.* --all && wait
  grep 0 <(systemctl --user list-units docker.* --all --no-pager) || echo F1
  grep inactive <(grep active <(systemctl --user is-active dbus) || echo F2) && echo F3; return 0
}

subver() {
  sub_ver=\$1
  rel_date=\$(date -d \"\$(date)\" +\"%m-%d-%Y-00\$sub_ver\")
  date_rel=\$(date -d \"\$(date)\" +\"%Y-%m-%d-00\$sub_ver\")
  declare -g -- rel_date; declare -g -- date_rel; 
  echo -e \"Build Subversion: 00\$sub_ver\n\" 
}

clean_some() {
if [[ \"$NO_CLEAN\" == \"\" ]]; then
  rm -r -f $home/docker/ \
  $home/.docker/ \
  $data_dir/rootless* \
  $data_dir/systemd/; fi;
}

validate.with.pki() { # \$1 = full_url.TDL/.../[file]
  ./.pki/local.sh \$1 \$CLIENT_ID || exit 1
}
docker() {
  echd=\"\$@\"; $docker \$echd
}
quiet() {
  echq=\"\$@\"; script -a -q -c \"\$echq\" $nulled >> $nulled
}
confirm() { # \$1 = subject
  read -p \"Press enter then 👆 please confirm presence on security token for \$1.\"
}

clean_some || echo \"Failed clean_some\"

if [[ \"$TESTS\" != *SKIP_LOGIN* ]]; then
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
  if [[ ! -d \".pki\" ]]; then mkdir -p .pki; git submodule add git@.pki:\$REPO/.pki.git;
  else git submodule --quiet foreach \"cd .. && git config submodule.\$name.url git@\$name:\$REPO/\$name.git\"; fi;
  git submodule update --init --remote --merge

  if [[ \"\$(gpg-card list - openpgp)\" == *\$SIGNING_KEY* && \"$DEBUG\" != *no* ]]; then
    echo -e '\nSigning key present' && mkdir -p $home/.password-store $home/$snap_path/ && pass init \$SIGNING_KEY && echo && \
    printf 'pass is initialized\npass is initialized\n' | pass insert docker-credential-helpers/docker-pass-initialized-check >> $nulled || exit 1
    mv -T $home/.password-store $home/$snap_path/.password-store || exit 1
    mv -T $home/.gnupg $home/$snap_path/.gnupg || exit 1; else
    echo && echo \"Signing key \$SIGNING_KEY missing\"
    echo -e '\nCheck Yubikey and .identity file\n'
    lsusb && ls -la /dev/hid* && gpg-card list - openpgp
    systemctl --user status gpg-agent* --all --no-pager
    ls -la $home/.gnupg $home/.password-store; exit 1
fi; fi;

unset source_date_epoch
if [[ \"\$EPOCH\" == *today* ]]; then timestamp=\$(date -d \$(date +%D) +%s);
  if [[ \"\$timestamp\" != \"\" ]]; then
    echo \"Setting SOURCE_DATE_EPOCH from today's date: \$(date +%D) = @\$timestamp\";
    source_date_epoch=\$((timestamp)); else echo \"Can't get timestamp. Defaulting to 1.\";
    source_date_epoch=1; fi;
elif [[ \"\$EPOCH\" != 0 ]]; then echo \"Using override timestamp \$EPOCH for SOURCE_DATE_EPOCH.\";
  source_date_epoch=\$((\$EPOCH)); else timestamp=\$(cat $results/release.sha512sum | grep Epoch | cut -d ' ' -f5);
  if [[ \"\$timestamp\" != \"\" ]]; then echo \"Setting SOURCE_DATE_EPOCH from release.sha512sum: \
\$(cat $results/release.sha512sum | grep Epoch | cut -d ' ' -f5)\";
    cp $results/release.sha512sum /tmp/release.last.sha512sum && check_file=yes || exit 1
    source_date_epoch=\$((timestamp)); else echo \"Can't get latest commit timestamp. Defaulting to 1.\";
    source_date_epoch=1; fi; fi;

unset rel_date date_rel rel_ver sub_ver
rel_date=\$(date -d \"\$(date)\" +\"%m-%d-%Y\")
date_rel=\$(date -d \"\$(date)\" +\"%Y-%m-%d\")
rel_ver=\$(git log --pretty=reference --grep=\\ \$date_rel | wc -l)
if [[ \"\$rel_ver\" -lt 1 ]]; then wait;
elif [[ \"\$rel_ver\" -gt 1 ]]; then subver \$rel_ver;
else sub_ver=1; subver \$sub_ver; fi;

export -- SOURCE_DATE_EPOCH=\$source_date_epoch SDE=\$source_date_epoch \
source_date_epoch=\$source_date_epoch sde=\$source_date_epoch
echo -e \"Setting rel_date from today's date: \$rel_date\n\"

if [[ \"$NO_CLEAN\" == \"\" ]]; then rm -r -f Results* $results*; mkdir -p $results/{arm64,amd64,source,env,debug}; fi;
mkdir -p $docker_data/{syft,grype,tmp} $local_bin $local_lib/$uname-$OSTYPE $rootless_path/tmp $sysusr_path || exit 1
touch $rootless_path/{env-{docker,rootless},tmp/env-rootless.exp} && > $rootless_path.sh && chmod +x $rootless_path.sh || exit 1

cat >> $rootless_path.sh << ____EOF
#!/bin/env -S - /bin/bash --norc --noprofile
$debug && export -- HOME=$home PATH=$path TERM=$term
mkdir -p $rootless_path/tmp && wait && > $rootless_path/env-docker
> $rootless_path/env-rootless && > $rootless_path/tmp/env-rootless.exp && wait
rootlesskit --net=slirp4netns --copy-up=/etc --copy-up=/run --copy-up=/sys/fs/cgroup --disable-host-loopback \
--ipv6 --cgroupns --pidns --slirp4netns-sandbox=true --slirp4netns-seccomp=true --evacuate-cgroup2=slirp4 \
--state-dir=$rootless_path/tmp /bin/env -- /bin/bash --norc --rcfile <(echo set -m) --noprofile -i -c '
env > $rootless_path/env-docker && grep ROOTLESS $rootless_path/env-docker > $rootless_path/env-rootless

echo \"BUILDKIT_MULTI_PLATFORM=true
BUILDKIT_PROGRESS=tty
BUILDKIT_TTY_LOG_LINES=$(($LINES - 10))
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
SOURCE_DATE_EPOCH=\$SDE
SYFT_CACHE_DIR=$docker_data/syft
TERM=$term
XDG_CONFIG_HOME=$home
XDG_SESSION_ID=\$XDG_USR_SESSION
XDG_RUNTIME_DIR=$run_dir\" >> $rootless_path/env-rootless

sed \"s/^/export -- /g\" $rootless_path/env-rootless > $rootless_path/tmp/env-rootless.exp
\$(echo \"echo echo $\(\<$rootless_path/env-rootless\)\" $dockerd --rootless \
--userland-proxy-path $docker_path/docker-proxy --init-path $docker_path/docker-init --init \
--feature cdi=false --cgroup-parent docker.slice --group $run_as --data-root $docker_data \
--exec-root $run_dir/docker --pidfile $run_dir/docker.pid) | /bin/bash --norc --noprofile | \
/bin/bash --norc --noprofile 2>> $rootless_path/rootless.log' 2>> $rootless_path/rootlesskit.log
____EOF

cp $systemd_service $sysusr_service && wait && \
sed -i \"s|Type.*|Type=exec|\" $sysusr_service && \
sed -z -i \"s|\n\[Service\]\nEnv|$(printf \"%s\\\\n\" $(echo $sed_ech))Env|\" $sysusr_service && \
sed -i \"s|EnvironmentFile.*|EnvironmentFile=-$rootless_path/env-rootless|\" $sysusr_service && \
sed -i \"s|Delegate.*|Delegate=cpu cpuset io memory pids|\" $sysusr_service && \
sed -i \"s|Syslog.*|SyslogIdentifier=docker.dockerd|\" $sysusr_service && \
sed -i \"s|X-Snappy.*|Conflicts=snap.docker_rootless.dockerd.service snap.docker.dockerd.service|\" $sysusr_service && \
sed -i \"s|ExecStart.*|ExecStart=/bin/env - /bin/bash -c \'$rootless_path.sh\'|\" $sysusr_service || exit 1

if [[ \"$DEBUG\" == *yes* ]]; then
  echo created: $rootless_path.sh
  cat $rootless_path.sh
  echo modified: $sysusr_service
  cat $sysusr_service
  echo original: $systemd_service
  cat $systemd_service
  read -p test_here; fi;

sys_ctl_common || true; systemctl --user start docker.dockerd; sleep 10;
systemctl --user status docker.slice docker.dockerd --all --no-pager -l > $rootless_path/dockerd.log || true
source $rootless_path/tmp/env-rootless.exp && echo \"$rootless_path/tmp/env-rootless.exp sourced\" || exit 1
quiet \"$docker info | grep rootless > $rootless_path/tmp/rootless.status\"

if [[ \"\$(grep root $rootless_path/tmp/rootless.status)\" != *rootless* ]]; then
  echo -e 'Rootless Docker Failed\n'; exit 1; else
  rootless='Rootless Docker Started\n'; echo -e \$rootless;
  echo -e \$rootless > $rootless_path/tmp/rootless.status; fi;

eval \"\$PUSHD_RESULTS && pushd env >> $pushd_log\"
  unset id save_id; id=\$(id -u)
  save_id=\$id:\$id.env; set > \$save_id
  env | sort >> \$save_id; declare >> \$save_id
  mv $docker_data/0:0.env .
  cp $rootless_path/env-docker docker.env

  echo -e '\nDocker Version:\n' > docker.info
  quiet '$docker version >> docker.info'
  echo -e '\nDocker Info:\n' >> docker.info
  quiet '$docker info >> docker.info'
  echo -e '\nBuildx Version:\n' >> docker.info
  quiet '$docker buildx version >> docker.info'
  echo -e '\nBuildx Inspect:\n' >> docker.info
  quiet '$docker buildx inspect --bootstrap >> docker.info'
  \$POPD; if [[ \"$DEBUG\" == *yes* ]]; then
  pushd debug >> $pushd_log
    mv $docker_data/snap.{info,install,events} .
  \$POPD; fi;
\$POPD; unset id save_id;

if [[ \"$TESTS\" != *SKIP_LOGIN* ]]; then
  if [[ \"\$(which docker-credential-pass)\" == \"\" ]]; then
    validate.with.pki \"\$cred_helper\" || exit 1
    echo \"\$cred_helper_sha  \$cred_helper_name\" | sha512sum -c || exit 1
    mv \$cred_helper_name $local_bin/docker-credential-pass && \
    chmod +x $local_bin/docker-credential-pass || exit 1
  else cp \$(which docker-credential-pass) $local_bin/docker-credential-pass || exit 1; fi;

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
  snap run --shell docker_rootless.docker -c 'PATH=\$PATH:$local_bin ; \
  LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:$local_lib/:$local_lib/$uname-$OSTYPE ; docker login' || exit 1
  mv -T $home/$snap_path/.password-store $home/.password-store || exit 1
  mv -T $home/$snap_path/.gnupg $home/.gnupg && echo Credentials: \$(\$credstat) || exit 1
  syft login registry-1.docker.io -u \$USERNAME && echo -e '\nLogged in to syft\n' || exit 1
fi

if [[ \"\$CROSS\" == *,* ]]; then
  if [[ \"\$(uname -m)\" == \"aarch64\" ]]; then docker run --privileged --cgroupns private --pull --rm \$binfmt_arm64 --install amd64;
  elif [[ \"\$(uname -m)\" == \"x86_64\" ]]; then docker run --privileged --cgroupns private --pull --rm \$binfmt_amd64 --install arm64;
  else echo 'Unknown Architecture '\$(uname -m); exit 1; fi; echo;
fi

if [[ \"$TESTS\" != *SKIP_LOGIN* && \"$DEBUG\" != *no* ]]; then
  source modules || drop_down || exit \$PIPESTATUS
  \$PUSHD_RESULTS
    scan_using_grype ubuntu \"/ --select-catalogers directory\"
    touch readme.md && > readme.md && cat */*.vulns >> readme.md
    cat *.vulns >> readme.md && sed -i 's/^/#### /g' readme.md
    echo '\`\`\`' >> readme.md && cat *.index.ref >> readme.md
    cat */*.manifest.ref >> readme.md && cat readme.md && echo
  \$POPD
  git status && git add -A && git status && confirm 'git commit - git@ssh'
  if [[ \"\$BRANCH\" != \"\" ]]; then
    git commit -a -S -m \"$COMMIT \$date_rel\" && \
    git push --set-upstream origin \$(git rev-parse --abbrev-ref HEAD):\$BRANCH
    if [[ \"\$TAG\" != \"\" ]]; then
      git tag -a \"\$TAG\" -s -m \"Tagged Release \$TAG\" && sleep 5 && \
      git push origin \"refs/tags/\$TAG\"
    fi; fi; else drop_down || echo \$PIPESTATUS
fi;

pids=\"\$pid_1 \$pid_2 \$pid_3\"
for pid in \$pids; do
  while [[ \$(cat <(lsof -F p -p \$pid -R | grep -o \$pid)) == *\$pid* ]]; do
    printf \$pid': pid still running...\n'; quiet kill \$pid && echo 'Killed pid: '\$pid; sleep 0.1;
  done; sleep 0.1; done; unset pid pids pid_1 pid_2 pid_3

docker-credential-pass erase &
ssh-add -D && eval \$(ssh-agent -k)
clean_some || echo \"Failed clean_some\"
sys_ctl_common || echo \"Failed systemctl_common\""

if [[ "$TEST" == *yes* ]]; then chown root:root $nulled $pushd_log; fi;
if [[ "$MOUNT" != "" ]]; then unmount; fi;
if [[ -d $home/$snap_path ]]; then declare -- dir_pid="$(cat <(lsof -F p $home/$snap_path | cut -d'p' -f2 || true))"; fi;

pids="$pid_0 $mk_pid $dir_pid $lsof_d"
for pid in $pids; do
  while [[ $(cat <(lsof -F p -p $pid -R | grep -o $pid)) == *$pid* ]]; do
    printf $pid': pid still running...'\\n; quiet kill $pid; echo 'Killed pid: '$pid; sleep 0.1;
  done; sleep 0.1; done; unset pid pids pid_0 mk_pid dir_pid lsof_d

clean_all || echo "Failed clean_all"
sed -i "s|:/home/root:|:/root:|" /etc/passwd
systemd_ctl_common unmask sleep\ 1 || echo \"Failed systemctl_common_unmask\"

if [[ "$NO_CLEAN" == "" ]]; then
  snap remove syft --purge --terminate
  snap remove grype --purge --terminate
  snap remove docker_rootless --purge --terminate 2>> $nulled && sleep 1
  snap remove docker_rootless --purge --terminate 2>> $nulled || echo "Failed to remove Docker Rootless"; fi;

clean_all || echo "Failed clean_all"
if [[ "$TEST" == "yes" ]]; then chown $run_as:$run_as $nulled $pushd_log; fi; exit 0
