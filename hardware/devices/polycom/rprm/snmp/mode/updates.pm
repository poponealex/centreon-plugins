#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package hardware::devices::polycom::rprm::snmp::mode::updates;

use base qw(centreon::plugins::templates::counter);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'updates-status', type => 2, critical_default => '%{updates_status} =~ /failed/i',set => {
                key_values => [ { name => 'updates_status' } ],
                closure_custom_output => $self->can('custom_updates_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'updates-failed', nlabel => 'rprm.updates.failed.count', set => {
                key_values => [ { name => 'updates_failed' } ],
                output_template => 'Failed last 60m: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'updates-successed', nlabel => 'rprm.updates.successed.count', set => {
                key_values => [ { name => 'updates_success' } ],
                output_template => 'Successed last 60m: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];
}

sub custom_updates_status_output {
    my ($self, %options) = @_;

    return sprintf('Current status: "%s"',  $self->{result_values}->{updates_status});
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'RPRM Updates jobs stats: ';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_serviceSoftwareUpdateStatus = '.1.3.6.1.4.1.13885.102.1.2.3.1.0';
    my $oid_serviceSoftwareUpdateFailuresLast60Mins = '.1.3.6.1.4.1.13885.102.1.2.3.2.0';
    my $oid_serviceSoftwareUpdateSuccessLast60Mins = '.1.3.6.1.4.1.13885.102.1.2.3.3.0';

    my %updates_status = ( 1 => 'disabled', 2 => 'ok', 3 => 'failed' );

    my $result = $options{snmp}->get_leef(
        oids => [
            $oid_serviceSoftwareUpdateStatus,
            $oid_serviceSoftwareUpdateFailuresLast60Mins,
            $oid_serviceSoftwareUpdateSuccessLast60Mins
        ],
        nothing_quit => 1
    );

    $self->{global} = {
        updates_status => $updates_status{$result->{$oid_serviceSoftwareUpdateStatus}},
        updates_failed => $result->{$oid_serviceSoftwareUpdateFailuresLast60Mins},
        updates_success => $result->{$oid_serviceSoftwareUpdateSuccessLast60Mins}
    };
}

1;

__END__

=head1 MODE

Check Polycom RPRM updates jobs

=over 8

=item B<--warning-updates-status>

Custom Warning threshold of the updates state (Default: none)
Syntax: --warning-updates-status='%{updates_status} =~ /clear/i'

=item B<--critical-updates-status>

Custom Critical threshold of the updates state
(Default: '%{updates_status} =~ /failed/i' )
Syntax: --critical-updates-status='%{updates_status} =~ /failed/i'

=item B<--warning-* --critical-*>

Warning and Critical thresholds.
Possible values are: updates-failed, updates-successed

=back

=cut
