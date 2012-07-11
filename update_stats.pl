#
#Snippet from data processing, this function is adding statistics to redis database
#
#Function gets data in arguments, and then saves statistics to global redis statistics, 
#but it has secondary function also where it must save statistics to daily results, and that is why it calculates date from timestamp, and
#calculates it relative to timezone
#
#

sub add_to_stats
{
	my ($checkId,$group,$value,$stamp,$slotValue,$timezone) = @_;
	
	my $redis = Redis->new(
		server => REDIS_SERVER,
		encoding => undef
	);
	$redis->select(7);
	
	$redis->hmset("$checkId-$group","total",$slotValue,"avg",$value*1000,"up",$slotValue);
	
	my $dt = DateTime->from_epoch( epoch => $stamp);
	my $tz = DateTime::TimeZone->new(name=>$timezone);
	
	$dt->set_time_zone($tz);
	
	my $day = ($dt->day()<10?"0".$dt->day():$dt->day()).(($dt->month())<10?"0".$dt->month():$dt->month()).$dt->year();
	
	$redis->select(6);
	
	$redis->hmset("$checkId-$group-$day","total",$slotValue,"avg",$value*1000,"up",$slotValue);
	
	$redis->quit;
}