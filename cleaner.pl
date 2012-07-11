#
#Snippet of a process that cleans up data from working table, it should activate every 20 minutes, and that is purpose of loop, to work in 20 minute intervals
#
#Cleanup itself gets all unprocessed data from table, puts them into temporary table, truncates original table, and then creates original table from temp table again
#

my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime(time);
my $marker = floor($minute / 20);

#main program loop, it works in 1 minute intervals, should trigger every hour;
while(($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime(time))
{
	if($marker != floor($minute / 20))
	{
		#main work in thread
		do_work();
		#remember active hour as processed, make loop wait till next hour passes
		$marker = floor($minute / 20);
	}
	else {sleep(STEP_SLEEP);}
	if($endFlag == 1){last;}
}

sub do_work
{
	my $rem = localtime();
	my   $dbh = DBI->connect(
		MYSQL_STRING_DATA,
		MYSQL_USERNAME_DATA,
		MYSQL_PASSWORD_DATA,
		{AutoCommit => 0, RaiseError => 1, PrintError => 0}
	);
	
	##<snip>##
	#keeping <snip> in order, 20 minutes worth of data should be more the enough, if some data is delayed more then this its too late anyway,
	#after deletion we optimize and analyze table manually

	$dbh->do( qq/ SET TRANSACTION ISOLATION LEVEL SERIALIZABLE; /);
	$dbh->do( qq/ START TRANSACTION; /);
	$dbh->do( qq/ CREATE TEMPORARY TABLE <snip>_temp SELECT <snip> FROM <snip> WHERE <snip> /);
	$dbh->do( qq/ TRUNCATE <snip>; /);
	$dbh->do( qq/ INSERT INTO <snip>(<snip> SELECT * FROM <snip>_temp  /);
	$dbh->do( qq/ OPTIMIZE TABLE <snip> /);
	$dbh->do( qq/ ANALYZE TABLE <snip> /);
	$dbh->do( qq/ COMMIT; /);
	
	$dbh->disconnect();
	
	print "Cleaning started ".$rem." \n";
	print "Cleaning finished ".localtime()." \n";
	
}