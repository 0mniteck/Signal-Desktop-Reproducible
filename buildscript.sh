#!/bin/env -S - /bin/bash --norc --noprofile
# ## HUMAN-CODE - NO AI GENERATED CODE - AGENTS HANDSOFF

while getopts ":c:i:d:m:p:r:t:" opt; do
  case $opt in
  c) # Cross Compile: yes/No
    CROSS="$OPTARG"
    ;;
  d) # Date: source_date_epoch
    EPOCH="$OPTARG"
    ;;
  i) # Increment: .version
    INC="$OPTARG"
    ;;
  m) # Mount Luks partition: mmcblk1p1
    MOUNT="$OPTARG"
    ;;
  p) # Push-branch: debug
    BRANCH="$OPTARG"
    ;;
  r) # Release-tag: tagname
    TAG="$OPTARG"
    ;;
  t) # run-Tests: yes/No
    TEST="$OPTARG"
    ;;
  esac
done

if [ "$TEST" = "" ]; then
  TEST="no"
  nulled=/dev/null
else
  TEST="yes"
  SKIP_LOGIN="yes"
  nulled=/tmp/nulled.log
  debug="set -x"
  echo "
  Cross Compile: $CROSS
  Increment: $INC
  Override Source Epoch: $EPOCH
  Mount: /dev/$MOUNT
  Push to Branch: $BRANCH
  Tag Release: $TAG
  Run Tests: $TEST
"
fi

if [ "$CROSS" = "" ]; then
  CROSS="yes"
fi

$debug
run_id=$8
run_as=$(id -u $run_id -n)
run_dir=/run/user/$run_id
run_home=/home/$run_as
term=xterm-256color
export -- HOME=$run_home PATH=/sbin:/bin:/snap/bin:$run_home/bin TERM=$term

if [[ "$run_id" == "" ]]; then
  if [[ "$(whoami)" == *root* ]]; then
    echo -e "\nDO NOT run with escalated priviledges!\nScript will Use: ~\$ 'pkexec --keep-cwd ./buildscript.sh'\n" && exit 1
  else
    echo -e "\nPkexec is required for installation steps\nUsing: ~\$ 'pkexec --keep-cwd ./buildscript.sh'\n"
    runm="exec pkexec --keep-cwd '$0' '$1' '$2' '$3' '$4' '$5' '$6' '$7' '$(id -u)'"
    if [[ "$(which asciinema)" != "" ]]; then
      repo=$(cat .identity | grep REPO= | cut -d'=' -f2)
      project=$(cat .identity | grep PROJECT= | cut -d'=' -f2)
      rel_date=$(date -d "$(date)" +%m-%d-%Y)
      mkdir -p $run_home/.casts/$repo && \
      exec asciinema rec --overwrite -t "$repo/$project:$rel_date" $run_home/.casts/$repo/$project:$rel_date.cast -c "$runm"
    else
      $runm
    fi
  fi
fi

if [ "$TEST" = "yes" ]; then
  touch $nulled
  chown root:root $nulled
fi

source .pinned_ver
if [[ "$(uname -m)" == "aarch64" ]]; then
  snap_path=snap/docker/$docker_snap_arm64_ver
  docker_snap_ver=$docker_snap_arm64_ver
  uname=aarch64
elif [[ "$(uname -m)" == "x86_64" ]]; then
  snap_path=snap/docker/$docker_snap_amd64_ver
  docker_snap_ver=$docker_snap_amd64_ver
  uname=x86_64
else
  echo 'Unknown Architecture '$(uname -m) && exit 1
fi

RUN_DIR=$run_dir
home=$HOME; path=$PATH
data_dir=$home/.local/share
sysusr_path=$data_dir/systemd/user
rootless_path=$data_dir/rootless
docker_data=$data_dir/docker
docker_path=/$snap_path/bin
docker=$docker_path/docker
systemd_service=/etc/systemd/system/snap.docker.dockerd.service
sysusr_service=$sysusr_path/docker.dockerd.service
plugins_path=usr/libexec/docker/cli-plugins
docker_plugins=/$plugins_path/docker-

sed_ech=$(cat << _EOF__
\\\\[Service\\\\]\\
Group=$run_as\\
Slice=docker.slice\\
_EOF__
)

quiet() {
  echt="$@"
  script -a -q -c "$echt" $nulled >> $nulled
}

clean_most() {
  rm -r -f /home/root/*
  rm -r -f /root/snap/docker/
  rm -r -f $data_dir/docker/
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
  clean_most
  rm -r -f /var/snap/docker/
  rm -r -f /usr/libexec/docker/
  rm -r -f /var/lib/snapd/cache/*
}

systemd_ctl_common() {
  snap stop docker && wait
  systemctl daemon-reload && wait
  systemctl reset-failed && wait
  systemctl stop snap.docker.* --all && wait
}

unmount() {
  quiet snap disable docker && sleep 1
  quiet kill $(lsof -F p $docker_data 2>> $nulled | cut -d'p' -f2) && \
  rm -r -f $docker_data/* && sync
  quiet umount $docker_data && sleep 1
  quiet systemd-cryptsetup detach Luks-Signal && sleep 1
  quiet dmsetup remove /dev/mapper/Luks-Signal && sleep 1
  rm -r -f $docker_data/ && sync
}

clean_all

apt-get -qq update && apt-get -qq upgrade -y && \
apt-get -qq install --no-install-recommends --purge --autoremove -u acl+ bc+ cosign+ dosfstools+ gh+ git-lfs+ gnupg2+ gpg-agent+ jq+ \
                                                                    parted+ pass+ pinentry-curses+ pkexec+ rootlesskit+ scdaemon+ \
                                                                    slirp4netns+ snapd+ systemd-container+ \
                                                                    systemd-cryptsetup+ uidmap+ \
                                                                    docker- docker.io- docker-ce- docker-ce-cli- || exit 1
if [ "$MOUNT" != "" ]; then
    unmount
fi

snap remove docker --purge 2>> $nulled && wait || echo "Failed to remove Docker"
snap install docker --revision=$docker_snap_ver || echo "Failed to install Docker"
snap install syft --classic
snap install grype --classic && echo

for d in docker-daemon firewall-control opengl privileged support; do
  ## active: home network network-bind network-control
  snap disconnect docker:$d >> $nulled && echo "Removing plug docker:"$d || exit 1
done && sleep 1 && echo

systemd_ctl_common
quiet systemctl mask snap.docker.nvidia-container-toolkit --runtime --now
quiet systemctl mask snap.docker.dockerd --runtime --now
mkdir -p /home/root && sed -i.backup "s|:/root:|:/home/root:|" /etc/passwd
quiet networkctl delete docker0

mkdir -p /$plugins_path && wait
ln -f -s /$snap_path${docker_plugins}buildx ${docker_plugins}buildx >> $nulled || exit 1
ln -f -s /$snap_path${docker_plugins}compose ${docker_plugins}compose >> $nulled || exit 1

clean_most

if [[ "$(cat /lib/udev/rules.d/60-scdaemon.rules | grep $run_as)" != *$run_as* ]]; then
  sed -i.backup "s/\"1050\", ATTR{idProduct}==\"040.\", /&MODE=\"0660\", GROUP=\"$run_as\", /g" \
  /lib/udev/rules.d/60-scdaemon.rules
  udevadm control --reload-rules && udevadm trigger
fi

if [[ "$SKIP_LOGIN" == "" ]]; then
  while [[ "$(lsusb | grep Yubikey)" != *Yubikey* ]]; do
    printf "\r🔐 Please insert yubikey...\033[K"
  done && sleep 1 && echo
fi

quiet chown $run_as:$run_as /dev/hidraw*
DEVICE=$(lsusb -d 1050: | grep -o Device.... - | grep -o [0-9][0-9][0-9])
BUS=$(lsusb -d 1050: | grep -o Bus.... - | grep -o [0-9][0-9][0-9])
set_facl="setfacl -m u:$run_as:rw /dev/bus/usb/$BUS/$DEVICE"
quiet $set_facl || quiet $set_facl || exit 1

rm -f -r $docker_data/ && mkdir -p $docker_data && chown $run_as:$run_as $docker_data

if [ "$MOUNT" != "" ]; then
  systemd-cryptsetup attach Luks-Signal /dev/$MOUNT && sleep 1 && echo
  mount /dev/mapper/Luks-Signal $docker_data && sleep 1
  rm -f -r $docker_data/* && chown $run_as:$run_as $docker_data
fi
if [ "$TEST" = "yes" ]; then
  chown $run_as:$run_as $nulled
else
  declare -- PUSH='"--push"'
fi
if [ "$CROSS" = "yes" ]; then
  declare -- CROSS='"--platform linux/arm64,linux/amd64"'
fi

pushd $docker_data > /dev/null
  save_id=0:0.env
  set > $save_id
  env | sort >> $save_id
  declare >> $save_id
  chown $run_as:$run_as $save_id
popd > /dev/null

machinectl shell $run_as@ /bin/env - /bin/bash --norc --noprofile -c "
$debug
cd $PWD

mkdir -p $home/.ssh && chmod 0700 $home/.ssh && \
touch $home/.ssh/config && chmod 0644 $home/.ssh/config

export -- \
SKIP_LOGIN=$SKIP_LOGIN PUSH=$PUSH PATH=$PATH \
HOME=$HOME CROSS=$CROSS EPOCH=$EPOCH INC=$INC \
MOUNT=$MOUNT BRANCH=$BRANCH TAG=$TAG TEST=$TEST \
DBUS_SESSION_BUS_ADDRESS=unix:path=$RUN_DIR/bus \
XDG_RUNTIME_DIR=$RUN_DIR GPG_TTY=\$(/bin/tty) \
SSH_CONF=\$(<$HOME/.ssh/config) TERM=$TERM \

eval \"\$(ssh-agent -s)\" && wait
systemctl --user restart gpg-agent.service && wait

source .identity
source .pinned_ver

chmod 0600 $home/\$PKI_ID_FILE && chmod 0644 $home/\$PKI_ID_FILE.pub
chmod 0600 $home/\$IDENTITY_FILE && chmod 0644 $home/\$IDENTITY_FILE.pub
gpg2 --quick-set-ownertrust \$USER_ID ultimate

clean_some() {
  rm -r -f /home/$run_as/docker/
  rm -r -f /home/$run_as/.docker/
  rm -r -f /home/$run_as/.local/share/rootless*
  rm -r -f /home/$run_as/.local/share/systemd/
}

confirm() { # \$1 = subject
  read -p \"Press enter then 👆 please confirm presence on security token for \$1.\"
}

if [[ \"\$SSH_CONF\" != *.pki* ]]; then
  echo \"
Host .pki
  Hostname github.com
  IdentityFile $home/\$PKI_ID_FILE
  IdentitiesOnly yes\" >> $home/.ssh/config
fi

if [[ \"\$SSH_CONF\" != *\$PROJECT* ]]; then
  echo \"
Host \$PROJECT
  Hostname github.com
  IdentityFile $home/\$IDENTITY_FILE
  IdentitiesOnly yes\" >> $home/.ssh/config
fi

if [[ \"\$SKIP_LOGIN\" == \"\" ]]; then
  ssh -T git@github.com 2>> $nulled
  ssh-add -t 1D -h git@github.com $home/\$IDENTITY_FILE
  ssh-add -t 1D -h git@github.com $home/\$PKI_ID_FILE
  ssh-add -l && echo
  git remote remove origin && git remote add origin git@\$PROJECT:\$REPO/\$PROJECT.git
  git-lfs install && git reset --hard && git clean -xfd
  confirm 'git fetch - git@ssh (twice)' && echo 'Starting Git fetch...'
  git fetch --unshallow 2>> $nulled
  confirm 'git pull - git@ssh' && echo 'Starting Git pull...'
  git pull \$(git remote -v | awk '{ print \$2 }' | tail -n 1) \$(git rev-parse --abbrev-ref HEAD)
  confirm 'git submodules - git@ssh (twice)' && echo 'Starting Git submodules...'
  git submodule add git@.pki:\$REPO/.pki.git
  git submodule --quiet foreach \"cd .. && git config submodule.\$name.url git@\$name:\$REPO/\$name.git\"
  git submodule update --init --remote --merge
  git submodule --quiet foreach \"git remote remove origin && git remote add origin git@\$name:\$REPO/\$name.git\"
  # echo && read -p '🔐 Press enter to start Github CLI login.' && gh auth login || exit 1
  if [[ \"\$(gpg-card list - openpgp)\" == *\$SIGNING_KEY* ]]; then
    echo -e '\nSigning key present\n'
    mkdir -p $home/.password-store && mkdir -p $home/$snap_path/.password-store || exit 1
    pass init \$SIGNING_KEY && echo
    printf 'pass is initialized\npass is initialized\n' | pass insert docker-credential-helpers/docker-pass-initialized-check >> $nulled
    confirm 'pass show - pinentry@gpg' && pass show docker-credential-helpers/docker-pass-initialized-check && echo || exit 1
    mv -T $home/.password-store $home/$snap_path/.password-store || exit 1
    mv -T $home/.gnupg $home/$snap_path/.gnupg || exit 1
  else
    echo && echo \"Signing key \$SIGNING_KEY missing\"
    echo -e '\nCheck Yubikey and .identity file\n'
    lsusb && ls -la /dev/hid* && gpg-card list - openpgp
    systemctl --user status gpg-agent* --all --no-pager
    ls -la $home/.gnupg && ls -la $home/.password-store
    exit 1
  fi
fi

clean_some

mkdir -p $rootless_path/tmp && wait && > $rootless_path.sh && \
> $rootless_path/env-docker && > $rootless_path/env-rootless && \
chmod +x $rootless_path.sh || exit 1

mkdir -p $home/bin && mkdir -p $home/docker && mkdir -p $home/.docker && \
mkdir -p $docker_data/syft && mkdir -p $docker_data/grype || exit 1

mkdir -p $home/lib/$uname-linux-gnu && \
cp /lib/$uname-linux-gnu/libassuan.so.9* $home/lib/$uname-linux-gnu/ || exit 1

mkdir -p $sysusr_path && wait && \
cp $systemd_service $sysusr_service || exit 1

cat >> $rootless_path.sh << __EOF
  #!/bin/env -S - /bin/bash --norc --noprofile
  $debug
  mkdir -p $rootless_path/tmp && wait
  > $rootless_path/env-docker && > $rootless_path/env-rootless && wait
  rootlesskit --copy-up=/etc --copy-up=/run --net=slirp4netns --disable-host-loopback --state-dir $rootless_path/tmp /bin/bash -i -c '
  env > $rootless_path/env-docker && grep ROOTLESS $rootless_path/env-docker > $rootless_path/env-rootless && rm -f $rootless_path/env-docker
  echo \"docker=$docker
  HOME=$home
  XDG_CONFIG_HOME=$home
  XDG_RUNTIME_DIR=$run_dir
  DBUS_SESSION_BUS_ADDRESS=unix:path=$run_dir/bus
  DOCKER_TMPDIR=$docker_data/tmp
  DOCKER_CONFIG=$home/docker
  DOCKER_HOST=unix://$run_dir/docker.sock
  BUILDX_METADATA_PROVENANCE=max
  BUILDX_METADATA_WARNINGS=1
  BUILDKIT_PROGRESS=tty
  NO_COLOR=true
  SOURCE_DATE_EPOCH=\$source_date_epoch
  SYFT_CACHE_DIR=$docker_data/syft
  GRYPE_DB_CACHE_DIR=$docker_data/grype
  PATH=$path:$docker_path\" >> $rootless_path/env-rootless
  sed \"s/^/export -- /g\" $rootless_path/env-rootless > $rootless_path/env-rootless.exp
  \$(echo \"echo echo $\(\<$rootless_path/env-rootless\)\" $(echo $docker)d --rootless \
  --userland-proxy-path $docker_path/docker-proxy --init-path $docker_path/docker-init --init \
  --feature cdi=false --cgroup-parent docker.slice --group $run_as --data-root $docker_data \
  --exec-root $run_dir/docker --pidfile $run_dir/docker.pid) | /bin/bash | /bin/bash 2>> $rootless_path/rootless.log'
__EOF

drop_down() {
  read -p 'Dropping down to shell; run source modules; or issue docker commands rootlessly;'
  env - bash --noprofile --rcfile <( cat <( declare -p | grep -- -- ); \
  echo 'docker() { echd=\"\$@\"; $docker \$echd; }'; \
  echo \"echo 'Dropped down to shell. exit when done, or press ctrl+d';echo; \
  PS1=\$PS1; declare -p | grep TEST; declare -p | grep SKIP; \
  PROMPT_COMMAND='echo;echo Rootless~Docker:~\$'\")
}

scan_using_grype() { # \$1 = Name, \$2 = Repo/Name:tag or '/Path --select-catalogers directory', \$3 = Platform(amd64/arm64), \$4 = Attest Tag
  src=\"--source-name \$1 --source-supplier 0mniteck42 --source-version \$(date +%s)\"
  if [[ \"\$3\" != \"\" ]]; then
    mkdir -p \$3 && pushd \$3
    arch=--platform\ \$3
    if [[ \"\$4\" != \"\" ]]; then
      if [[ \"\$SKIP_LOGIN\" == \"\" ]]; then
        read -p '🔐 Press enter to start attestation for \$3' && echo
        echo 'Starting Syft...'
        touch .pager && tail -f .pager & pid=\$!
        syft_att_run=\"script -q -c 'TMPDIR=$docker_data/syft syft attest \$arch -o spdx-json docker.io/\$REPO/\$1:\$4' /dev/null > .pager\"
    	  quiet \$syft_att_run || quiet \$syft_att_run || exit 1
        kill \$pid && rm -f .pager
        echo
      else
        echo 'Skipping attestation: not logged in'
      fi
    else
      echo 'Starting Syft...'
    fi
  else
    pushd .
  fi
  touch \$1.syft.tmp && tail -f \$1.syft.tmp & pidd=\$!
  syft_run=\"script -q -c 'TMPDIR=$docker_data/syft syft scan \$2 \$src \$arch -o spdx-json=\$1.spdx.json' /dev/null > \$1.syft.tmp\"
  quiet \$syft_run || quiet \$syft_run || exit 1
  kill \$pidd && rm -f -r $docker_data/syft/*
  echo && echo 'Starting Grype...'
  grype config > $docker_data/.grype.yaml
  touch \$1.grype.tmp && tail -f \$1.grype.tmp & piddd=\$!
  script -q -c \"TMPDIR=$docker_data/grype grype sbom:\$1.spdx.json \
  -c $docker_data/.grype.yaml \$arch -o json --file \$1.grype.json\" /dev/null > \$1.grype.tmp
  kill \$piddd && rm -f -r $docker_data/grype/*
  marker() { # \$1 = Name, \$2 = Order, \$4 = Marker/ID, \$3 = syft/grype
    unset \"wright\$2\"
    grep \"\$4\" \$1.\$3.tmp | tail -n 1 > \$1.\$3.status.\$2
    line1=\$(cat \$1.\$3.status.\$2)
    if [[ \"\$line1\" == *\$4* ]]; then
      export -- \"wright\$2\"=\"\$line1\"
    fi
		rm -f \$1.\$3.tmp*
		rm -f \$1.\$3.status.*
  }
  wright() { # \$1 = Name, \$2 = syft/grype
		echo \$wright1 > \$1.\$2.status
		echo \$wright2 >> \$1.\$2.status
		echo \$wright3 >> \$1.\$2.status
		echo \$wright4 >> \$1.\$2.status
		echo \$wright5 >> \$1.\$2.status
		sed -i 's/[^[:print:]]//g' \$1.\$2.status
		sed -i 's/\[K//g' \$1.\$2.status
		sed -i 's/\[2A//g' \$1.\$2.status
		sed -i 's/\[3A//g' \$1.\$2.status
	}
	gryped() { # \$1 = Name
		marker \$1 1 grype \"✔ Scanned for vulnerabilities\"
		marker \$1 2 grype \"├── by severity:\"
		marker \$1 3 grype \"└── by status:\"
		wright \$1 grype
	}
	syfted() { # \$1 = Name
		marker \$1 1 syft \"✔ Cataloged contents\"
		marker \$1 2 syft \"├── ✔ Packages\"
		marker \$1 3 syft \"├── ✔ Executables\"
		marker \$1 4 syft \"├── ✔ File metadata\"
		marker \$1 5 syft \"└── ✔ File digests\"
		wright \$1 syft
	}
	syfted &&	gryped
	echo '### '\$1' Syft Scan Results - '\$(syft --version) > \$1.contents
	cat \$1.syft.status >> \$1.contents && rm -f \$1.syft.status
	echo '### '\$1' Grype Scan Results - '\$(grype --version) >> readme.md
	cat \$1.grype.status >> readme.md
	echo '## ' >> readme.md
  popd
}

sys_ctl_common() {
  systemctl --user daemon-reload && wait
  systemctl --user reset-failed && wait
  systemctl --user stop docker* --all && wait
  systemctl --user list-units docker* --all && echo
}

quiet() {
  echt=\"\$@\"
  script -a -q -c \"\$echt\" $nulled >> $nulled
}

docker() {
  echd=\"\$@\"
  $docker \$echd
}

validate.with.pki() { # \$1 = full_url.TDL/.../[file]
  chmod +x .pki/local.sh && ./.pki/local.sh \$1 || exit 1
}

sed -z -i \"s|\[Service\]\nEnv|$(printf \"%s\\\\n\" $(echo $sed_ech))Env|\" $sysusr_service
sed -i \"s|EnvironmentFile.*|EnvironmentFile=-$rootless_path/env-rootless|\" $sysusr_service
sed -i \"s|ExecStart.*|ExecStart=/bin/bash -c \'$data_dir/rootless.sh\'|\" $sysusr_service

sys_ctl_common
systemctl --user start docker.dockerd && sleep 10
systemctl --user status docker.dockerd --all --no-pager -n 150 > $rootless_path/rootless.ctl.log
source $rootless_path/env-rootless.exp
quiet \"$docker info | grep rootless > $rootless_path/rootless.status\"

if [[ \"\$(grep root $rootless_path/rootless.status)\" != *rootless* ]]; then
  echo -e 'Rootless Docker Failed\n' && exit 1
else
  rootless='Rootless Docker Started\n'
  echo -e \$rootless
  echo -e \$rootless > $rootless_path/rootless.status
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
  timestamp=\$(cat Results/release.sha512sum | grep Epoch | cut -d ' ' -f5)
  if [[ \"\$timestamp\" != \"\" ]]; then
    echo \"Setting SOURCE_DATE_EPOCH from release.sha512sum: \$(cat Results/release.sha512sum | grep Epoch | cut -d ' ' -f5)\"
    source_date_epoch=\$((timestamp))
    check_file=1
    cp Results/release.sha512sum /tmp/release.last.sha512sum
  else
    echo \"Can't get latest commit timestamp. Defaulting to 1.\"
    source_date_epoch=1
  fi
fi
echo && SOURCE_DATE_EPOCH=\$source_date_epoch

unset rel_date date_rel rel_ver sub_ver
rel_date=\$(date -d \"\$(date)\" +\"%m-%d-%Y\")
date_rel=\$(date -d \"\$(date)\" +\"%Y-%m-%d\")
rel_ver=\$(git log --pretty=reference --grep=Successful\\ Build\\ of\\ Release\\ \$date_rel | wc -l)
sub_ver=\$(git submodule --quiet foreach \"git log --pretty=reference --grep=\$rel_date\" | wc -l)

subver() {
  sub_ver=\$1
  rel_date=\$(date -d \"\$(date)\" +\"%m-%d-%Y-00\$sub_ver\")
  date_rel=\$(date -d \"\$(date)\" +\"%Y-%m-%d-00\$sub_ver\")
  echo \"Build Subversion: 00\$sub_ver\" && echo 
}

if [[ \"\$rel_ver\" -lt 1 ]]; then
  wait
elif [[ \"\$sub_ver\" -ge 1 ]]; then
  subver \$sub_ver
else
  sub_ver=1
  subver \$sub_ver
fi

if [[ \"\$SKIP_LOGIN\" == \"\" ]]; then
  if [[ \"\$(which docker-credential-pass)\" == \"\" ]]; then
    validate.with.pki \"\$cred_helper\" || exit 1
    echo \"\$cred_helper_sha  \$cred_helper_name\" | sha512sum -c || exit 1
    mv \$cred_helper_name $home/bin/docker-credential-pass || exit 1
    chmod +x $home/bin/docker-credential-pass && \
    echo '{
  \"credsStore\": \"pass\"
}' > $home/docker/config.json && \
    installed='which docker-credential-pass' && \
    echo Installed at: \$(\$installed) || exit 1
    cp \$(which pass) $home/bin/pass && \
    echo Installed at: $home/bin/pass && \
    cp \$(which gpg) $home/bin/gpg && \
    echo Installed at: $home/bin/gpg || exit 1
    echo Installed at: $home/lib/$uname-linux-gnu/libassuan.so.9
  fi
  credstat='docker-credential-pass list'
  echo && read -p '🔐 Press enter to start docker login.'
  snap run --shell docker.docker -c 'PATH=\$PATH:$home/bin ; LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:$home/lib/:$home/lib/aarch64-linux-gnu ; docker login' || exit 1
  mv -T $home/$snap_path/.password-store $home/.password-store && mv -T $home/$snap_path/.gnupg $home/.gnupg && \
  echo Credentials: \$(\$credstat) && cp $home/docker/* $home/.docker/ || exit 1
  
  read -p TEST_HERE1
  syft login registry-1.docker.io -u \$USERNAME && echo -e '\nLogged in to syft\n' || exit 1
  grype login registry-1.docker.io -u \$USERNAME && echo -e 'Logged in to grype\n' || exit 1
fi

if [[ \"\$(uname -m)\" == \"aarch64\" ]]; then
  docker run --privileged --rm tonistiigi/binfmt:qemu-v10.0.4-59 --install amd64
elif [[ \"\$(uname -m)\" == \"x86_64\" ]]; then
  docker run --privileged --rm tonistiigi/binfmt:qemu-v10.0.4-59 --install arm64
else
  echo 'Unknown Architecture '\$(uname -m) && exit 1
fi
echo

mkdir -p Results && pushd Results > /dev/null
  save_id=$run_id:$run_id.env
  set > $save_id
  env | sort >> $save_id
  declare >> $save_id
  mv $docker_data/0:0.env 0:0.env
  quiet '$docker version > docker.info'
  echo >> docker.info
  quiet '$docker info >> docker.info'
popd > /dev/null

read -p TEST_HERE2
if [[ \"\$SKIP_LOGIN\" == \"\" ]]; then
  chmod -x modules && source modules || drop_down || exit 1
else
  drop_down || exit 1
fi

pushd Results > /dev/null
  scan_using_grype ubuntu \"/ --select-catalogers directory\"
  sed -i 's/^/#### /g' readme.md && echo '\`\`\`' >> readme.md
  cat *.image.digest >> readme.md && cat readme.md && echo
popd > /dev/null

if [[ \"\$SKIP_LOGIN\" == \"\" ]]; then
  git status && git add -A && git status && confirm 'git commit - git@ssh'
  if [ \"\$BRANCH\" != \"\" ]; then
    git commit -a -S -m \"Successful Build of Release \$date_rel\" && git push --set-upstream origin \$(git rev-parse --abbrev-ref HEAD):\$BRANCH
    if [ \"\$TAG\" != \"\" ]; then
      git tag -a \"\$TAG\" -s -m \"Tagged Release \$TAG\" && sleep 5 && git push origin \"refs/tags/\$TAG\"
    fi
  fi
fi

docker-credential-pass erase
ssh-add -D && eval \"\$(ssh-agent -k)\"
clean_some
sys_ctl_common"

if [ "$TEST" = "yes" ]; then
  chown root:root $nulled
fi
if [ "$MOUNT" != "" ]; then
    unmount
fi

clean_all
quiet systemctl unmask snap.docker.nvidia-container-toolkit --runtime --now
quiet systemctl unmask snap.docker.dockerd --runtime --now
sed -i "s|:/home/root:|:/root:|" /etc/passwd
quiet networkctl delete docker0
systemd_ctl_common

quiet kill $(lsof -F p $home/$snap_path 2>> $nulled | cut -d'p' -f2) && \
rm -r -f $home/$snap_path/* && sync
snap remove docker --purge 2>> $nulled && wait
snap remove docker --purge 2>> $nulled || echo "Failed to remove Docker"
snap remove grype --purge
snap remove syft --purge
clean_all

if [ "$TEST" = "yes" ]; then
  chown $run_as:$run_as $nulled
fi
exit 0
