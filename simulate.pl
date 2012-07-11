#
#Code snippets from simulation created to test processing data part of system
#It reads configuration from json config file, and creates timeline of data points
#

sub simulate
{
	my $interval = $json_text->{interval};
	
	my $seed;
	if($seeded == 0){$seed = int(rand($interval*60));}
	else{$seed = $seeded;}
	
	print "\n Seed: $seed\n";
	
	get_nodes($json_text->{cluster});
	
	my $mode = 0;
	
	my $clusterSize = scalar(@nodes);
	
	reset_regular($clusterSize);	
	
	if($clusterSize == 0 ){die "Misconfigured nodes\n";}
	
	my $miniSeed = $seed % (60/$clusterSize);

	for(my $t = $st;$t<($st + (TIMELINE * 60));$t++)
	{
		if($mode == 0)
		{
			if(($t)%($interval*60)==$seed)
			{
				my $cNode = determine_node($t,$mode,$clusterSize,$interval);
				$mode = generate_entry($t,$mode,$miniSeed,$clusterSize,$interval,$nodes[$cNode][0],$nodes[$cNode][1]);
			}
		}
		else
		{
			if(($t-$st)%(($interval*60)/$clusterSize)==$miniSeed)
			{
				my $cNode = determine_node($t,$mode,$clusterSize,$interval);
				$mode = generate_entry($t,$mode,$miniSeed,$clusterSize,$interval,$nodes[$cNode][0],$nodes[$cNode][1]);
			}
		}
	}

}

#Quick algorithm for shuffling array
#Useful when we are running simulation in random mode, we shuffle timeline after it has been generated, but it can work with any 1D array

sub fisher_yates_shuffle {
    my $array = shift;
    my $i;
    for ($i = @$array; --$i; ) {
        my $j = int rand ($i+1);
        next if $i == $j;
        @$array[$i,$j] = @$array[$j,$i];
    }
}