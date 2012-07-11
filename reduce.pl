#Function snippet from one of data processing systems 
#
#An example of custom algorithm, and data retrieving and storing in PERL
#
#Objective is to accept arbitrary amount of data points from one day, and to reduce it to DAILY_LIMIT amount of information, for example
#if we had 1440 data points in a day and we want them to reduce to 48 average points throughout the day, we can use this function,
#Function is getting parameters as arguments, and data itself is retrieved from redis database, and saved at the same time
#
#Note that connection to redis server itself is taken as granted for this example
#
#Also it should be noted that some data points might be missing, and there could actually be less data points then DAILY_LIMIT so function will try to expand 
#available data as best as it can
#



sub reduce_vals
{
	my ($checkId,$group,$hlimit,$llimit,$interval,$clusterSize) = @_;
	
	my $mode = 1;
	
	while((24*3600 / (DAILY_LIMIT / $mode )) < (60*$interval*$clusterSize))
	{
		$mode = $mode*2;
	}
	
	my $size = 24*3600 / (DAILY_LIMIT / $mode);
	
	my $redisVals = Redis->new(
		server => REDIS_SERVER,
		encoding => undef
	);
	#8 are values
	$redisVals->select(8);
	
	my @tempList;
	my @results;
	
	$redisVals->watch("$checkId-$group");
	my @vals = $redisVals->lrange("$checkId-$group",0,-1);
	my @newVals;
	
	if($debug)
	{
		print "Reducing values-> llimit: $llimit, hlimit: $hlimit, mode: $mode\n";
	}
	
	foreach my $value (@vals)
	{
		my @segment = split(":",$value);
		if($segment[2] > $llimit){push @newVals,$value;}
		if($segment[2] <  $llimit || $segment[2] >= $hlimit){next;}
		my $slot = int(($segment[2] - $llimit) /  $size);
		my @oldVals = (0,0);
		if(defined $tempList[$slot])
		{
			@oldVals = split(":",$tempList[$slot]);
		}
		if($segment[0]==1)
		{
			$tempList[$slot] = (1+$oldVals[0]).":".($segment[1]+$oldVals[1]);
			$results[$slot] = sprintf("%.6f", ($segment[1]+$oldVals[1])/(1+$oldVals[0]));
		}
		else
		{
			$tempList[$slot] = $oldVals[0].":".$oldVals[1];
			$results[$slot] = ($oldVals[0]==0)?0:sprintf("%.6f",($oldVals[1]/$oldVals[0]));
		}
	}
	for(my $i = 0; $i<(DAILY_LIMIT/$mode);$i++)
	{
		if(!defined $results[$i])
		{
			$results[$i] = -1;
		}
	}
	if($mode>1)
	{
		@results = inflate_results($mode,@results);
	}
	
	#cleanup of old data from active_results
	$redisVals->multi();
	$redisVals->del("$checkId-$group");
	$redisVals->rpush("$checkId-$group",@newVals);
	my @responses = $redisVals->exec();
	if($debug){
		print "Responses after first exec: ".join(" ",@responses)."\n";
	}
	my $counter = 0;
	while(!@responses)
	{
		$redisVals->multi();
		my @vals = $redisVals->lrange("$checkId-$group",0,-1);
		my @newVals;
		foreach my $value (@vals)
		{
			my @segment = split(":",$value);
			if(scalar @segment != 3){next;}
			if($segment[2] > $llimit){push @newVals,$value;}	
		}
		$redisVals->del("$checkId-$group");
		if(scalar(@newVals)==0){$redisVals->discard();next;}
		$redisVals->rpush("$checkId-$group",@newVals);
		@responses = $redisVals->exec();
		$counter++;
		if($counter > 5)
		{
			print "Stuck in loop while trying to handle $checkId active results\n";
			last;
		}
	}
	
	$redisVals->quit();
	return @results;
}