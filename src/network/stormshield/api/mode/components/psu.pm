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

package network::stormshield::api::mode::components::psu;

use strict;
use warnings;

sub load {}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking power supplies');
    $self->{components}->{psu} = { name => 'psu', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'psu'));

    my ($exit, $warn, $crit, $checked);
    foreach my $label (keys %{$self->{results}}) {
        next if ($label !~ /POWERSUPPLY_POWER(\d+)/i);
        my $instance = 'psu' . $1;
        my $num = $1;

        next if ($self->check_filter(section => 'psu', instance => $instance));

        $self->{results}->{$label}->{status} = lc($self->{results}->{$label}->{status});

        $self->{components}->{psu}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "power supply '%s' status is %s [instance: %s, fan: %s rpm]",
                $num,
                $self->{results}->{$label}->{status},
                $instance,
                $self->{results}->{$label}->{fan_speed}
            )
        );

        $exit = $self->get_severity(section => 'psu', value => $self->{results}->{$label}->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Power supply '%s' status is %s", $instance, $self->{results}->{$label}->{status}
                )
            );
        }

        next if ($self->{results}->{$label}->{status} ne 'ok');

        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'fan', instance => $instance, value => $self->{results}->{$label}->{fan_speed});            
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Power supply '%s' speed is '%s' rpm", $num, $self->{results}->{$label}->{fan_speed}
                )
            );
        }

        $self->{output}->perfdata_add(
            nlabel => 'hardware.fan.speed.rpm',
            unit => 'rpm',
            instances => $instance,
            value => $self->{results}->{$label}->{fan_speed},
            warning => $warn,
            critical => $crit,
            min => 0
        );
    }
}

1;
