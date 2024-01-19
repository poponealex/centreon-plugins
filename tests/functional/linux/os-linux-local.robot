*** Settings ***
Documentation       Hardware UPS standard SNMP plugin

Library             OperatingSystem
Library             String

Test Timeout        120s


*** Variables ***
${CENTREON_PLUGINS}         ${CURDIR}${/}..${/}..${/}..${/}src${/}centreon_plugins.pl

${CMD}                      perl ${CENTREON_PLUGINS} --plugin=os::linux::local::plugin

&{linux_local_test_1}
...                         filtername=
...                         excludename=
...                         warningstatus=
...                         criticalstatus=
...                         warningtotalrunning=
...                         criticaltotalrunning=
...                         warningtotaldead=
...                         criticaltotaldead=
...                         warningtotalexited=
...                         criticaltotalexited=
...                         warningtotalfailed=
...                         criticaltotalfailed=
...                         result=OK: Total Running: 40, Total Failed: 0, Total Dead: 120, Total Exited: 40 - All services are ok | 'total_running'=40;;;0;414 'total_failed'=0;;;0;414 'total_dead'=120;;;0;414 'total_exited'=40;;;0;414

@{linux_local_tests}
...                         &{linux_local_test_1}

*** Test Cases ***
Linux Local Systemd-sc-status
    [Documentation]    Linux Local Systemd services status
    [Tags]    os    linux    local
    FOR    ${linux_local_test}    IN    @{linux_local_tests}
        ${command}    Catenate
        ...    ${CMD}
        ...    --mode=systemd-sc-status
        ...    --verbose
        ${length}    Get Length    ${linux_local_test.filtername}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --filter-name=${linux_local_test.filtername}
        END

        ${output}    Run    ${command}
        ${output}    Strip String    ${output}
        Should Be Equal As Strings
        ...    ${output}
        ...    ${linux_local_test.result}
        ...    Wrong result output for:${\n}Command: ${\n}${command}${\n}${\n}Expected output: ${\n}${linux_local_test.result}${\n}${\n}Obtained output:${\n}${output}${\n}${\n}${\n}
        ...    values=False
    END
