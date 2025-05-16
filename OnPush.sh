#!/usr/bin/env bash
# Written in [Amber](https://amber-lang.com/)
# version: 0.4.0-alpha
# date: 2025-05-16 16:15:00

file_exists__33_v0() {
    local path=$1
     [ -f "${path}" ] ;
    __AS=$?;
if [ $__AS != 0 ]; then
        __AF_file_exists33_v0=0;
        return 0
fi
    __AF_file_exists33_v0=1;
    return 0
}
env_var_load__85_v0() {
    local var=$1
    local file=$2
    __AMBER_VAL_0=$( echo "${!var}" );
    __AS=$?;
    local _var="${__AMBER_VAL_0}"
    if [ $([ "_${_var}" == "_" ]; echo $?) != 0 ]; then
        __AF_env_var_load85_v0="${_var}";
        return 0
fi
    file_exists__33_v0 "${file}";
    __AF_file_exists33_v0__11_8="$__AF_file_exists33_v0";
    if [ "$__AF_file_exists33_v0__11_8" != 0 ]; then
         source "${file}" ;
        __AS=$?
        __AMBER_VAL_1=$( echo "${!var}" );
        __AS=$?;
        __AF_env_var_load85_v0="${__AMBER_VAL_1}";
        return 0
fi
    __AF_env_var_load85_v0="";
    return 0
}
env_file_load__86_v0() {
    local file=$1
     export "$(xargs < ${file})" > /dev/null ;
    __AS=$?
}
array_find__112_v0() {
    local array=("${!1}")
    local value=$2
    index=0;
for element in "${array[@]}"; do
        if [ $([ "_${value}" != "_${element}" ]; echo $?) != 0 ]; then
            __AF_array_find112_v0=${index};
            return 0
fi
    (( index++ )) || true
done
    __AF_array_find112_v0=$(echo  '-' 1 | bc -l | sed '/\./ s/\.\{0,1\}0\{1,\}$//');
    return 0
}
array_contains__114_v0() {
    local array=("${!1}")
    local value=$2
    array_find__112_v0 array[@] "${value}";
    __AF_array_find112_v0__26_18="$__AF_array_find112_v0";
    local result="$__AF_array_find112_v0__26_18"
    __AF_array_contains114_v0=$(echo ${result} '>=' 0 | bc -l | sed '/\./ s/\.\{0,1\}0\{1,\}$//');
    return 0
}
declare -r args=("$0" "$@")
    env_file_load__86_v0 ".env";
    __AF_env_file_load86_v0__5_5="$__AF_env_file_load86_v0";
    echo "$__AF_env_file_load86_v0__5_5" > /dev/null 2>&1
    env_var_load__85_v0 "PROJ" ".env";
    __AF_env_var_load85_v0__6_16="${__AF_env_var_load85_v0}";
    PROJ="${__AF_env_var_load85_v0__6_16}"
    env_var_load__85_v0 "FRONT" ".env";
    __AF_env_var_load85_v0__7_17="${__AF_env_var_load85_v0}";
    FRONT="${__AF_env_var_load85_v0__7_17}"
    env_var_load__85_v0 "BACK" ".env";
    __AF_env_var_load85_v0__8_16="${__AF_env_var_load85_v0}";
    BACK="${__AF_env_var_load85_v0__8_16}"
    array_contains__114_v0 args[@] "FRONTEND";
    __AF_array_contains114_v0__10_28="$__AF_array_contains114_v0";
    rebuild_frontend="$__AF_array_contains114_v0__10_28"
    array_contains__114_v0 args[@] "BACKEND";
    __AF_array_contains114_v0__11_27="$__AF_array_contains114_v0";
    rebuild_backend="$__AF_array_contains114_v0__11_27"
    if [ $(echo $(echo  '!' ${rebuild_frontend} | bc -l | sed '/\./ s/\.\{0,1\}0\{1,\}$//') '&&' $(echo  '!' ${rebuild_backend} | bc -l | sed '/\./ s/\.\{0,1\}0\{1,\}$//') | bc -l | sed '/\./ s/\.\{0,1\}0\{1,\}$//') != 0 ]; then
        echo "No work specified. Exiting"
        exit 0
fi
    if [ ${rebuild_backend} != 0 ]; then
        # TODO: set up staging
        # Have someone handle this on server
        echo "Automated backend rebuilding NOT implemented"
        echo "Exiting"
        exit 1
fi
    # build frontend
    echo ">> Rebulding Frontend"
    cd ${PROJ};
    __AS=$?;
if [ $__AS != 0 ]; then
        echo "Failed $__AS: Could not move to '${PROJ}'"
        exit $__AS
fi
    OLD_VERSION=""
    OLD_VERSION=$(npm run --prefix ${FRONT} version --silent);
    __AS=$?;
if [ $__AS != 0 ]; then
        __AMBER_VAL_2=$(date +%s);
        __AS=$?;
        OLD_VERSION="${__AMBER_VAL_2}"
fi
    git pull;
    __AS=$?;
if [ $__AS != 0 ]; then
        echo "Failed $__AS: Could not pull changes"
        exit $__AS
fi
    # TODO: Check if npm install if needed
    npm run --prefix ${FRONT} build:CF_TOKEN;
    __AS=$?;
if [ $__AS != 0 ]; then
        echo "Build step failed"
        exit $__AS
fi
    backup="build.${OLD_VERSION}.bak"
    echo -n "Backing up previous build... ";
    __AS=$?
    mv ${BACK}/build ${BACK}/old_builds/${backup};
    __AS=$?;
if [ $__AS != 0 ]; then
        echo "Failed"
        exit $__AS
fi
    echo "Done"
    echo -n "Moving new build to backend... ";
    __AS=$?
    mv ${FRONT}/build ${BACK};
    __AS=$?;
if [ $__AS != 0 ]; then
        echo "Failed"
        echo -n "Restoring previous build... ";
        __AS=$?
        mv ${BACK}/old_builds/${backup} ${BACK}/build;
        __AS=$?
        echo "Restored"
        exit $__AS
fi
    echo "Moved"
    echo "Build and Transfer Complete"
    exit 0
