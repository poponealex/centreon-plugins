#
# Copyright 2023 Centreon (http://www.centreon.com/)
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

package network::citrix::netscaler::snmp::mode::storage;
    
use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'storage', type => 1, cb_prefix_output => 'prefix_storage_output', message_multiple => 'All storages are ok' }
    ];

    $self->{maps_counters}->{storage} = [
        { label => 'usage', set => {
                key_values => [ { name => 'display' }, { name => 'used' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold')
            }
        }
    ];
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my $label = 'used';
    my $value_perf = $self->{result_values}->{used};
    if (defined($self->{instance_mode}->{option_results}->{free})) {
        $label = 'free';
        $value_perf = $self->{result_values}->{free};
    }

    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        label => $label, unit => 'B',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => $value_perf,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, %total_options),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;

    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
    $threshold_value = $self->{result_values}->{free} if (defined($self->{instance_mode}->{option_results}->{free}));
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
        $threshold_value = $self->{result_values}->{prct_free} if (defined($self->{instance_mode}->{option_results}->{free}));
    }
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    my $msg = sprintf("Usage Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                   $total_size_value . " " . $total_size_unit,
                   $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
                   $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free});
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'};
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};

    return 0;
}

sub prefix_storage_output {
    my ($self, %options) = @_;

    return "Storage '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s'   => { name => 'filter_name' },
        'units:s'         => { name => 'units', default => '%' },
        'free'            => { name => 'free' }
    });

    return $self;
}

my $mapping = {
    sysHealthDiskName   => { oid => '.1.3.6.1.4.1.5951.4.1.1.41.8.1.1' },
    sysHealthDiskSize   => { oid => '.1.3.6.1.4.1.5951.4.1.1.41.8.1.2' }, # in MB
    sysHealthDiskUsed   => { oid => '.1.3.6.1.4.1.5951.4.1.1.41.8.1.4' }, # in MB
};
my $oid_nsSysHealthDiskEntry = '.1.3.6.1.4.1.5951.4.1.1.41.8.1';

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{storage} = {};
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_nsSysHealthDiskEntry,
        nothing_quit => 1
    );

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{sysHealthDiskName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{sysHealthDiskName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{sysHealthDiskName} . "': no matching filter.", debug => 1);
            next;
        }

        $result->{sysHealthDiskSize} *= 1024 * 1024;
        $result->{sysHealthDiskUsed} *= 1024 * 1024;
        $self->{storage}->{$instance} = { 
            display => $result->{sysHealthDiskName},
            total => $result->{sysHealthDiskSize},
            used => $result->{sysHealthDiskUsed}
        };
    }
    
    if (scalar(keys %{$self->{storage}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No storage found.');
        $self->{output}->option_exit();
    }
}
    
1;

__END__

=head1 MODE

Check disk usages (NS-MIB-smiv2).

=over 8

=item B<--filter-name>

Filter storage name (can be a regexp).

=item B<--warning-usage>

Warning threshold.

=item B<--critical-usage>

Critical threshold.

=item B<--units>

Units of thresholds (default: '%') ('%', 'B').

=item B<--free>

Thresholds are on free space left.

=back

=cut
    
