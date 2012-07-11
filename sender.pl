#
#Code snippet from socket sending function,
#It loops over data from database, and sends each data part to its destination, using POE system for perl
#
#On the other side is also one socket that recieves data

sub sender{
	my $empty = 0;
	
	$sth->execute();
	while (my @row = $sth->fetchrow_array())
	{
		my $outboxId = shift @row;
		my $nodeId = shift @row;
		my $data = join('%',@row);
		
		$data = PACKAGE_HEADER.'#&##'.$data;
		
		$nodesql->execute($nodeId);
		
		my @now = $nodesql->fetchrow_array();
		
		if($nodesql->rows != 1){
			$yesql->execute($outboxId);
			next;
		}
		
		POE::Component::Client::TCP->new(
			RemoteAddress => $now[0],
			RemotePort    => $now[1],
			Filter        => "POE::Filter::Line",
			ConnectTimeout=> 10,
			Connected     => sub {
				#print "connected to $ip:$port ...\n";
				$_[HEAP]->{server}->put($data);
			},
			ConnectError => sub {
				#print "failed to connect to $ip:$port ...\n";
					$nosql->execute($outboxId);	
				},
			ServerInput => sub {
				#when the server answer the question
				my ($kernel, $heap, $input) = @_[KERNEL, HEAP, ARG0];
				
				if($input =~ m/K/ )
				{
					$yesql->execute($outboxId);
				}
				else
				{
					$nosql->execute($outboxId);
				}
				$_[KERNEL]->yield("shutdown");
			},
		);
		$poe_kernel->run();
		
		if($debug){
			print "Sent $data to node $nodeId\n";
		}
		
		$dbhData->commit();
	}
}

#
#Server side of data transfer communication

sub reciever
{
	POE::Component::Server::TCP->new(
		Alias        => "command_server",
		Port         => $port,
		ClientFilter => "POE::Filter::Line",
		ClientInput  => \&handle_client,
		Started => sub {
			print "Listening on port $port\n";
		},
		ClientConnected => sub {
			print localtime()." ::  Client connected from ".$_[HEAP]->{remote_ip}."\n";
		},
		ClientDisconnected => sub{
			print localtime()." ::  Client disconnected from ".$_[HEAP]->{remote_ip}."\n";
		},
	);
	$poe_kernel->run();

	sub handle_client{
		my ($sender, $heap, $input) = @_[SESSION, HEAP, ARG0];
		
		if(processCommand($input) > 0)
		{
			$heap->{client}->put($yes);
		}
		else
		{
			$heap->{client}->put($no);
		}
	}
	
}