#
# Copyright 2024 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package centreon::common::powershell::backupexec::jobs;

use strict;
use warnings;
use centreon::common::powershell::functions;
use centreon::common::powershell::backupexec::functions;

sub get_powershell {
    my (%options) = @_;

    my $ps = '
$ProgressPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"

$culture = new-object "System.Globalization.CultureInfo" "en-us"    
[System.Threading.Thread]::CurrentThread.CurrentUICulture = $culture
';

    $ps .= centreon::common::powershell::functions::escape_jsonstring(%options);
    $ps .= centreon::common::powershell::functions::convert_to_json(%options);
    $ps .= centreon::common::powershell::backupexec::functions::powershell_init(%options);

    $ps .= '

Try {
    $ErrorActionPreference = "Stop"

    $sessions = @{}
    Get-BEJobHistory -FromLastJobRun | ForEach-Object {
        $jobId = $_.JobId.toString()
        $sessions[$jobId] = @{}
        $sessions[$jobId].status = $_.JobStatus.value__
        $sessions[$jobId].creationTimeUTC = (get-date -date $_.StartTime.ToUniversalTime() -Uformat ' . "'%s'" . ')
        $sessions[$jobId].endTimeUTC = (get-date -date $_.EndTime.ToUniversalTime() -Uformat ' . "'%s'" . ')
        $sessions[$jobId].elapsedTime = $_.ElapsedTime.totalSeconds
    }

    $items = New-Object System.Collections.Generic.List[Hashtable];
    Get-BEJob | ForEach-Object {
        $item = @{}
        $item.name = $_.Name
        $item.type = $_.JobType.value__
        $item.isActive = $_.isActive
        $item.status = $_.Status.value__
        $item.subStatus = $_.SubStatus.value__
        $item.creationTimeUTC = ""
        $item.endTimeUTC = ""
        $item.elapsedTime = 0

        $id = $_.Id.toString()
        if ($sessions.ContainsKey($id)) {
            $item.status = $sessions[$id].status
            $item.creationTimeUTC = $sessions[$id].creationTimeUTC
            $item.endTimeUTC = $sessions[$id].endTimeUTC
            $item.elapsedTime = $sessions[$id].elapsedTime
        }

        $items.Add($item)
    }

    $jsonString = $items | ConvertTo-JSON-20 -forceArray $true
    Write-Host $jsonString
} Catch {
    Write-Host $Error[0].Exception
    exit 1
}

exit 0
';

    return $ps;
}

1;

__END__

=head1 DESCRIPTION

Method to get backup exec jobs.

=cut
