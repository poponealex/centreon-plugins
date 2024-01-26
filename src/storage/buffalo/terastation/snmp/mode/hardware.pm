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

package storage::buffalo::terastation::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{cb_hook2} = 'snmp_execute';

    $self->{thresholds} = {
        disk => [
            ['notSupport', 'WARNING'],
            ['normal', 'OK'],
            ['array1', 'OK'],
            ['array2', 'OK'],
            ['standby', 'OK'],
            ['degrade', 'WARNING'],
            ['remove', 'OK'],
            ['standbyRemoved', 'OK'],
            ['degradeRemoved', 'WARNING'],
            ['removeRemoved', 'OK'],
            ['array3', 'OK'],
            ['array4', 'OK'],
            ['mediaCartridge', 'OK'],
            ['array5', 'OK'],
            ['array6', 'OK']
        ],
        iscsi => [
            ['unknown', 'WARNING'],
            ['connected', 'OK'],
            ['standing-by', 'OK']
        ],
        psu => [
            ['unknown', 'WARNING'],
            ['fine', 'OK'],
            ['broken', 'CRITICAL']
        ]
    };
    
    $self->{components_path} = 'storage::buffalo::terastation::snmp::mode::components';
    $self->{components_module} = ['disk', 'psu', 'iscsi'];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, no_performance => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub snmp_execute {
    my ($self, %options) = @_;
    
    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
}

1;

__END__

=head1 MODE

Check hardware.

=over 8

=item B<--component>

Which component to check (default: '.*').
Can be: 'disk', 'iscsi', 'psu'.

=item B<--filter>

Exclude the items given as a comma-separated list (example: --filter=disk --filter=psu).
You can also exclude items from specific instances: --filter=psu,1

=item B<--no-component>

Define the expected status if no components are found (default: critical).

=item B<--threshold-overload>

Use this option to override the status returned by the plugin when the status label matches a regular expression (syntax: section,status,regexp).
Example: --threshold-overload='disk,OK,^(?!(degrade)$)'

=back

=cut
