# install dependencies:
#  sudo apt install cpanminus libjson-xs-perl libjson-perl libmysqlclient-dev libdbi-perl
#  sudo cpanm Net::WebSocket::Server
#  sudo cpanm DBD::MariaDB

use strict;
use warnings;
use JSON;
use Getopt::Long;
use DBI;

use Net::WebSocket::Server;
use Protocol::WebSocket::Frame;

$Protocol::WebSocket::Frame::MAX_PAYLOAD_SIZE = 100*1024*1024;
$Protocol::WebSocket::Frame::MAX_FRAGMENTS_AMOUNT = 102400;
    
$| = 1;

my $port = 8800;

my $network;

my $dsn = 'DBI:MariaDB:database=chaindb;host=localhost';
my $db_user = 'chaindb';
my $db_password = 'ce5Sxish';
my $commit_every = 10;
my $endblock = 2**32 - 1;
    
my $ok = GetOptions
    ('network=s' => \$network,
     'port=i'    => \$port,
     'ack=i'     => \$commit_every,
     'endblock=i'  => \$endblock,
     'dsn=s'     => \$dsn,
     'dbuser=s'  => \$db_user,
     'dbpw=s'    => \$db_password,
    );


if( not $ok or not $network or scalar(@ARGV) > 0 )
{
    print STDERR "Usage: $0 --network=XXX [options...]\n",
    "Options:\n",
    "  --port=N           \[$port\] TCP port to listen to websocket connection\n",
    "  --ack=N            \[$commit_every\] Send acknowledgements every N blocks\n",
    "  --network=NAME     name of EOS network\n",
    "  --endblock=N       \[$endblock\] Stop before given block\n",
    "  --dsn=DSN          \[$dsn\]\n",
    "  --dbuser=USER      \[$db_user\]\n",
    "  --dbpw=PASSWORD    \[$db_password\]\n";
    exit 1;
}


my $dbh = DBI->connect($dsn, $db_user, $db_password,
                       {'RaiseError' => 1, AutoCommit => 0,
                        mariadb_server_prepare => 1});
die($DBI::errstr) unless $dbh;

my $sth_add_transfer = $dbh->prepare
    ('INSERT INTO TRANSFERS ' .
     '(network, seq, block_num, block_time, trx_id, ' .
     'contract, currency, amount, decimals, tx_from, tx_to, memo) ' .
     'VALUES(?,?,?,?,?,?,?,?,?,?,?,?)');


my $sth_wipe_transfers = $dbh->prepare
    ('DELETE FROM TRANSFERS WHERE network=? AND block_num >= ? AND block_num < ?');


my $sth_add_balance = $dbh->prepare
        ('INSERT INTO BALANCES ' . 
         '(network, account_name, block_num, block_time, contract, currency, amount, decimals, deleted) ' .
         'VALUES(?,?,?,?,?,?,?,?,?)');

my $sth_wipe_balances = $dbh->prepare
    ('DELETE FROM BALANCES WHERE network=? AND block_num >= ? AND block_num < ?');


my $sth_add_userres = $dbh->prepare
        ('INSERT INTO USERRES ' . 
         '(network, account_name, block_num, block_time, cpu_weight, net_weight, ram_bytes) ' .
         'VALUES(?,?,?,?,?,?,?)');

my $sth_wipe_userres = $dbh->prepare
    ('DELETE FROM USERRES WHERE network=? AND block_num >= ? AND block_num < ?');


my $committed_block = 0;
my $uncommitted_block = 0;
my $json = JSON->new;

my %alldecimals;


Net::WebSocket::Server->new(
    listen => $port,
    on_connect => sub {
        my ($serv, $conn) = @_;
        $conn->on(
            'binary' => sub {
                my ($conn, $msg) = @_;
                my ($msgtype, $opts, $js) = unpack('VVa*', $msg);
                my $data = eval {$json->decode($js)};
                if( $@ )
                {
                    print STDERR $@, "\n\n";
                    print STDERR $js, "\n";
                    exit;
                } 
                
                my $ack = process_data($msgtype, $data);
                if( $ack > 0 )
                {
                    $conn->send_binary(sprintf("%d", $ack));
                    print STDERR "ack $ack\n";
                }

                if( $ack >= $endblock )
                {
                    print STDERR "Reached end block\n";
                    exit(0);
                }
            },
            'disconnect' => sub {
                my ($conn) = @_;
                print STDERR "Disconnected\n";
                $dbh->rollback();
                $committed_block = 0;
                $uncommitted_block = 0;
            },
            
            );
    },
    )->start;


sub process_data
{
    my $msgtype = shift;
    my $data = shift;

    if( $msgtype == 1001 ) # CHRONICLE_MSGTYPE_FORK
    {
        my $block_num = $data->{'block_num'};
        print STDERR "fork at $block_num\n";
        $sth_wipe_transfers->execute($network, $block_num, $endblock);
        $sth_wipe_balances->execute($network, $block_num, $endblock);
        $sth_wipe_userres->execute($network, $block_num, $endblock);
        $dbh->commit();
        $committed_block = $block_num;
        $uncommitted_block = 0;
        return $block_num;
    }
    elsif( $msgtype == 1007 ) # CHRONICLE_MSGTYPE_TBL_ROW
    {
        my $kvo = $data->{'kvo'};
        if( ref($kvo->{'value'}) eq 'HASH' )
        {
            if( $kvo->{'table'} eq 'accounts' )
            {
                if( defined($kvo->{'value'}{'balance'}) and
                    $kvo->{'scope'} =~ /^[a-z0-5.]+$/ )
                {
                    my $bal = $kvo->{'value'}{'balance'};
                    if( $bal =~ /^([0-9.]+) ([A-Z]{1,7})$/ )
                    {
                        my $amount = $1;
                        my $currency = $2;
                        my $contract = $kvo->{'code'};
                        my $block_time = $data->{'block_timestamp'};
                        $block_time =~ s/T/ /;
                        
                        my $decimals = get_decimals($contract, $amount, $currency);
                        $amount *= 10**$decimals;
                         
                        my $deleted = ($data->{'added'} eq 'true')?0:1;
                        if( $deleted )
                        {
                            $amount = 0;
                        }
                        
                        $sth_add_balance->execute
                            ($network, $kvo->{'scope'}, $data->{'block_num'}, $block_time,
                             $contract, $currency, $amount, $decimals, $deleted);
                    }
                }
            }
            elsif( $kvo->{'code'} eq 'eosio' )
            {
                if( $kvo->{'table'} eq 'userres' )
                {
                    my ($cpu, $curr1) = split(/\s/, $kvo->{'value'}{'cpu_weight'});
                    my ($net, $curr2) = split(/\s/, $kvo->{'value'}{'net_weight'});
                    my $block_time = $data->{'block_timestamp'};
                    $block_time =~ s/T/ /;

                    my $precision = 10 ** get_decimals('eosio.token', $cpu, $curr1);
                    
                    $sth_add_userres->execute
                        ($network, $kvo->{'value'}{'owner'}, $data->{'block_num'}, $block_time,
                         $cpu*$precision, $net*$precision, $kvo->{'value'}{'ram_bytes'});
                }
            }
        }
    }
    elsif( $msgtype == 1003 ) # CHRONICLE_MSGTYPE_TX_TRACE
    {
        my $trace = $data->{'trace'};
        if( $trace->{'status'} eq 'executed' )
        {
            my $block_num = $data->{'block_num'};
            my $trx_id = $trace->{'id'};
            my $block_time = $data->{'block_timestamp'};
            $block_time =~ s/T/ /;
                        
            foreach my $atrace (@{$trace->{'action_traces'}})
            {
                my $act = $atrace->{'act'};
                my $contract = $act->{'account'};
                my $receipt = $atrace->{'receipt'};
                
                if( $atrace->{'receipt'}{'receiver'} eq $contract )
                {
                    my $seq = $receipt->{'global_sequence'};
                    my $aname = $act->{'name'};
                    my $data = $act->{'data'};
                    if( ref($data) eq 'HASH' )
                    {
                        if( ($aname eq 'transfer' or $aname eq 'issue') and 
                            defined($data->{'quantity'}) and defined($data->{'to'}) )
                        {
                            my ($amount, $currency) = split(/\s+/, $data->{'quantity'});
                            if( defined($amount) and defined($currency) and
                                $amount =~ /^[0-9.]+$/ and $currency =~ /^[A-Z]{1,7}$/ )
                            {
                                my $decimals = get_decimals($contract, $amount, $currency);
                                $amount *= 10**$decimals;
                                
                                $sth_add_transfer->execute
                                    (
                                     $network,
                                     $seq,
                                     $block_num,
                                     $block_time,
                                     $trx_id,
                                     $contract,
                                     $currency,
                                     $amount,
                                     $decimals,
                                     $data->{'from'},
                                     $data->{'to'},
                                     $data->{'memo'}
                                    );
                            }
                        }
                    }
                }
            }
        }
    }
    elsif( $msgtype == 1009 ) # CHRONICLE_MSGTYPE_RCVR_PAUSE
    {
        if( $uncommitted_block > $committed_block )
        {
            $dbh->commit();
            $committed_block = $uncommitted_block;
            return $committed_block;
        }
    }
    elsif( $msgtype == 1010 ) # CHRONICLE_MSGTYPE_BLOCK_COMPLETED
    {
        $uncommitted_block = $data->{'block_num'};
        if( $uncommitted_block - $committed_block >= $commit_every or
            $uncommitted_block >= $endblock )
        {
            $dbh->commit();
            $committed_block = $uncommitted_block;
            return $committed_block;
        }
    }

    return 0;
}



sub get_decimals
{
    my $contract = shift;
    my $amount = shift;
    my $currency = shift;

    if( not defined($alldecimals{$contract}{$currency}) )
    {
        my $decimals = 0;
        my $pos = index($amount, '.');
        if( $pos > -1 )
        {
            $decimals = length($amount) - $pos - 1;
        }

        $alldecimals{$contract}{$currency} = $decimals;
        return $decimals;
    }

    return $alldecimals{$contract}{$currency};
}
    

   
