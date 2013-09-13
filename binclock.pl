#!/usr/bin/env perl

my %replace = (
    0 => $ARGV[0],
    1 => $ARGV[0],
);
$replace{0} =~ s/\{\}/$ARGV[1]/g;
$replace{1} =~ s/\{\}/$ARGV[2]/g;

my $formatstr = $ARGV[3];

sub tobin {
    my $i = shift;
    my $str = unpack("B32", pack("N", $i));
    return $str;
}

sub sprintbin {
    my $stack = $_[0];
    my $result = "";
    while ($stack =~ /(.)/g) {
        $result .= "$replace{$1}";
    }
    return $result
}

sub ct {
    tobin($_[1]) =~ /.*(.{$_[0]})/;
    return sprintbin($1);
}

my @tdata = localtime(time);
my @t = @tdata[0..4,6];

# 0 -> sec
# 1 -> min
# 2 -> hr
# 3 -> day
# 4 -> month
# 5 -> weekday

@t[4] += 1;                 # months are 0..11 in perl
@t[5] = 7 if @t[5] == 0;    # sunday is 0

my @cutlist = (6, 6, 5, 5, 4, 3); # number of bits needed for each value
my $i = 0;
foreach (@cutlist) {
    @t[$i] = ct($_, @t[$i]);
    $i++;
}

$formatstr =~ s/(?<!\\)%([0-9])/@t[$1]/g;
$formatstr =~ s/\\%/%/g;

print "$formatstr";
