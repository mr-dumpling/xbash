#!/bin/bash
#####-----------------------变量------------------------------#########
readonly rModuleName=module/tools/build/serialBuildByBranchName.sh
readonly rRirPathProcessEnableId=/tmp/ProcessEnableIds

isUpload=
isBackupOut=true
filePathBranchList=$1
fileNamePID=$2

#####----------------------初始化build环境--------------------------#######
# 函数
if [ -f $rFilePathCmdModuleToolsSpecific ];then
    source  $rFilePathCmdModuleToolsSpecific
else
    echo -e "\033[1;31m    函数加载失败\n\
    模块=$rModuleName\n\
    toolsPath=$rFilePathCmdModuleToolsSpecific\n\
    \033[0m"
fi
branchArray=($(cat $filePathBranchList))
if [ -z "$branchArray" ];then
    ftEcho -e "分支信息读取失败"
    read -n1 ddd
    exit;
fi
branchName="${branchArray[$fileNamePID]}"
# filePathEnableState=${rRirPathProcessEnableId}/${fileNamePID}
# while [[ ! -f "$filePathEnableState" ]]||[[ "enable" != $(cat $filePathEnableState) ]]; do
#     sleep 5
# done
# =============================================================
ftEcho -s "任务 ${fileNamePID} :开始执行"

ftAutoInitEnv
local cpuCount=$(cat /proc/cpuinfo| grep "cpu cores"| uniq)
cpuCount=$(echo $cpuCount |sed s/[[:space:]]//g)
cpuCount=${cpuCount//cpucores\:/}
if [[ $AutoEnv_mnufacturers = "sprd" ]]; then
            #if [ "$TARGET_PRODUCT" != "sp7731c_1h10_32v4_oversea" ];then
                source build/envsetup.sh&&
                lunch sp7731c_1h10_32v4_oversea-user&&
                kheader&&
                make -j${cpuCount} 2>&1|tee -a out/build_$(date -d "today" +"%y%m%d%H%M%S").log||break
                if [ $isUpload = "true" ];then
                    ftAutoPacket -a
                else
                    ftAutoPacket
                fi
                if [ $isBackupOut = "true" ];then
                    ftBackupOrRestoreOuts
                fi
            # fi
elif [[ $AutoEnv_mnufacturers = "mtk" ]]; then
        local deviceName=`basename $ANDROID_PRODUCT_OUT`
        if [ $deviceName = "keytak6580_weg_l" ];then
            source build/envsetup.sh&&
            lunch full_keytak6580_weg_l-user&&
            mkdir out
            make -j${cpuCount} 2>&1|tee -a out/build_$(date -d "today" +"%y%m%d%H%M%S").log||break

            branchName=$(echo $AutoEnv_branchName | tr '[A-Z]' '[a-z]') #转小写
            if [[ "$branchName" != *fm* ]];then
                make otapackage
            fi

            if [ $isUpload = "true" ];then
                ftAutoPacket -a
            else
                ftAutoPacket
            fi
            if [ $isBackupOut = "true" ];then
                ftBackupOrRestoreOuts
            fi
        fi
fi


# =============================================================
fileNamePID=$(expr $fileNamePID + 1)
if (( ${#branchArray[@]}==$fileNamePID ));then
    /bin/rm -f $rRirPathProcessEnableId
    exit
fi
echo enable > ${rRirPathProcessEnableId}/${fileNamePID}
