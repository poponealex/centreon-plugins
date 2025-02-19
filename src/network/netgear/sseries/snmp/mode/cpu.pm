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

package network::netgear::sseries::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_cpu_output {
    my ($self, %options) = @_;
    
    return 'cpu average usage: ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_cpu_output' }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'cpu-utilization-5s', nlabel => 'cpu.utilization.5s.percentage', set => {
                key_values => [ { name => 'usage_5s' } ],
                output_template => '%.2f %% (5s)',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100 }
                ]
            }
        },
        { label => 'cpu-utilization-1m', nlabel => 'cpu.utilization.1m.percentage', set => {
                key_values => [ { name => 'usage_1m' } ],
                output_template => '%.2f %% (1m)',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100 }
                ]
            }
        },
        { label => 'cpu-utilization-5m', nlabel => 'cpu.utilization.5m.percentage', set => {
                key_values => [ { name => 'usage_5m' } ],
                output_template => '%.2f %% (5m)',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    # STRING: "    5 Secs ( 43.2625%)   60 Secs ( 13.9157%)  300 Secs (  8.9274%)"
    my $oid_agentSwitchCpuProcessTotalUtilization = '.1.3.6.1.4.1.4526.11.1.1.4.9.0';
    my $snmp_result = $options{snmp}->get_leef(oids => [$oid_agentSwitchCpuProcessTotalUtilization], nothing_quit => 1);

    $snmp_result->{$oid_agentSwitchCpuProcessTotalUtilization} =~ /\s*5\s*Secs\s*\(\s*(.*?)%\s*\)\s*60\s*Secs\s*\(\s*(.*?)%\s*\)\s*300\s*Secs\s*\(\s*(.*?)%\s*\)/i;
    $self->{global} = { usage_5s => $1, usage_1m => $2, usage_5m => $3 };
}

1;

__END__

=head1 MODE

Check cpu usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='5m'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'cpu-utilization-1s', 'cpu-utilization-1m', 'cpu-utilization-5m'.

=back

=cut
