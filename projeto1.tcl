if {$argc == 3} {
	set cenario [lindex $argv 0]
	set protocolo [lindex $argv 1]
	set quebra [lindex $argv 2]
	#set velocidade [lindex $argv 3]
	if {$cenario != 1 && $cenario != 2} {
		puts "Escolha cenário 1 ou cenário 2."
		exit 1
	}
	if {$protocolo != "udp" && $protocolo != "tcp" && $protocolo != ""} {
		puts "Escolha entre udp ou tcp."
		exit 1
	}
	if {$quebra != 1 && $quebra != 0} {
		puts "Escolha 1 (Sim) ou 0 (Nao)."
		exit 1
	}
	#if {$velocidade <0} {
	#	puts "A velocidade tem de ser multipla de 1 Mb"
	#	exit 1
	#}

} elseif {$argc == 4} { 
	set cenario  [lindex $argv 0]
	set protocolo [lindex $argv 1]
	set quebra [lindex $argv 2]
	set window [lindex $argv 3]
	if {$cenario != 1 && $cenario != 2} {
		puts "Escolha cenário 1 ou cenário 2."
		exit 1
	}
	if {$protocolo != "udp" && $protocolo != "tcp" && $protocolo != ""} {
		puts "Escolha entre udp ou tcp."
		exit 1
	}
	if {$quebra != 1 && $quebra != 0} {
		puts "Escolha 1 (Sim) ou 0 (Nao)."
		exit 1
	}
	if {$window < 0} {
		puts "Escolha algum valor positivo para a janela"
		exit 1
	}
} else {
    puts "Argumentos: ns trab.tcl <cenario> <protocolo> <quebra> <janela>"
    puts "Cenario: 1 ou 2"
    puts "Protocolo: udp ou tcp"
    puts "Quebra: 1(sim) ou 0(nao)"
    puts "Janela: qualquer valor positivo"
    exit 1
}
# ---------------------------------------
set ns [new Simulator]

# protocolo de routing din,mico
$ns rtproto LS
# cores
$ns color 1 Blue
$ns color 2 Red
$ns color 3 Green

set nt [open out.tr w]
$ns trace-all $nt

set nf [open out.nam w]
$ns namtrace-all $nf


proc fim {} {
  global ns nf
  $ns flush-trace
  close $nf
  exec nam out.nam
  exit 0;
}

# set nodes
set pca [$ns node] 
set pcb [$ns node]
set pcc [$ns node]
set r3 [$ns node]
set r4 [$ns node]
set pcd [$ns node]
set r6 [$ns node]
set pce [$ns node]

#cores dos nodes
$pca color Blue
$pcb color red
$pcd color green
$pce color Blue
#forma
$pca shape "hexagon"
$pcb shape "square"
$pcd shape "square"
$pce shape "hexagon"
#legend
$pca label "PC A"
$pcb label "PC B"
$pcc label "PC C"
$pcd label "PC D"
$pce label "PC E"
$r3 label "R3"
$r4 label "R4"
$r6 label "R6"

# ligaçoes
#$ns duplex-link $pca $pcb $velocidade 10ms DropTail
$ns duplex-link $pca $pcb 10Mb 10ms DropTail
$ns duplex-link $pcb $pcc 10Mb 10ms DropTail
$ns simplex-link $r4 $pcb 10Mb 5ms DropTail
$ns duplex-link $pcc $pcd 10Mb 10ms DropTail
$ns duplex-link $pcc $r3 10Mb 10ms DropTail
$ns duplex-link $r3 $r6 10Mb 10ms DropTail
$ns duplex-link $r4 $pcd 10Mb 10ms DropTail
$ns duplex-link $pcd $r6 10Mb 10ms DropTail
$ns duplex-link $pcd $pce 10Mb 10ms DropTail

# --------- orientaçoes -----------
$ns duplex-link-op $pca $pcb orient right
$ns duplex-link-op $pcb $pcc orient right
$ns simplex-link-op $r4 $pcb orient up
$ns duplex-link-op $r4 $pcd orient right
$ns duplex-link-op $pcd $r6 orient right
$ns duplex-link-op $pcc $r3 orient right
$ns duplex-link-op $pcc $pcd orient down
$ns duplex-link-op $r3 $r6 orient down
$ns duplex-link-op $pcd $pce orient down


# -----------------queue ----------------------
$ns duplex-link-op $pca $pcb queuePos 0.5
$ns duplex-link-op $pcb $pcc queuePos 0.5
$ns simplex-link-op $r4 $pcb queuePos 0.5
$ns duplex-link-op $r4 $pcd queuePos 0.5
$ns duplex-link-op $pcd $r6 queuePos 0.5
$ns duplex-link-op $pcc $r3 queuePos 0.5
$ns duplex-link-op $pcc $pcd queuePos 0.5
$ns duplex-link-op $r3 $r6 queuePos 0.5
$ns duplex-link-op $pcd $pce queuePos 0.5

#limit
$ns queue-limit $pca $pcb 2098

# CENÁRIO 1: A -> E por udp ou tcp
# CENÁRIO 2: cenário 1 + (B->D: 6Mb/s + D->C: 5Mb/s) por udp

if {$protocolo == "udp"} {
	#-----------------SET UDP----------------------
	# A a E
	set udp0 [new Agent/UDP]
	$ns attach-agent $pca $udp0
	#---------------SET CBR------------------------
	set cbr0 [new Application/Traffic/CBR]
	$cbr0 set packetSize_ 2097152
	$cbr0 set maxpkts_ 1
	$cbr0 attach-agent $udp0
	#--------------------NULL AGENT---------------------
	set null0 [new Agent/Null]
	$ns attach-agent $pce $null0
	#-----------CONNECT UDP A NULL AGENTS --------------
	$ns connect $udp0 $null0
	#cor
	$udp0 set class_ 1
	# tempos
	$ns at 0.5 "$cbr0 start"
	$ns at 5.5 "$cbr0 stop"

} elseif {$protocolo == "tcp"} {
	#-----------------SET TCP----------------------
	# A a E
	set tcp [$ns create-connection TCP $pca TCPSink $pce 1]
	$tcp set window_ $window
	#---------------SET CBR------------------------
	set cbr0 [new Application/Traffic/CBR]
	$cbr0 set packetSize_ 2097152
	$cbr0 set maxpkts_ 1
	$cbr0 attach-agent $tcp
	#cor
	$tcp set class_ 1
	# tempos
	$ns at 0.5 "$cbr0 start"
}

if {$cenario == 2} {
	#-----------------SET UDP----------------------
	# B a D
	set udp1 [new Agent/UDP]
	$ns attach-agent $pcb $udp1
	# D a C
	set udp2 [new Agent/UDP]
	$ns attach-agent $pcd $udp2
	#---------------SET CBR------------------------
	set cbr1 [new Application/Traffic/CBR]
	$cbr1 set rate_ 6Mbps
	$cbr1 attach-agent $udp1

	set cbr2 [new Application/Traffic/CBR]
	$cbr2 set rate_ 5Mb
	$cbr2 attach-agent $udp2
	#--------------------NULL AGENT---------------------
	# B a D
	set null1 [new Agent/Null]
	$ns attach-agent $pcd $null1
	# D a C
	set null2 [new Agent/Null]
	$ns attach-agent $pcc $null2
	#-----------CONNECT UDP A NULL AGENTS --------------
	$ns connect $udp1 $null1
	$ns connect $udp2 $null2
	#cor
	$udp1 set class_ 2
	$udp2 set class_ 3
	#tempos
	$ns at 0.5 "$cbr1 start"
	$ns at 0.5 "$cbr2 start"
}

if {$quebra == 1} {
	$ns rtmodel-at 0.75 down $pcc $pcd
	$ns rtmodel-at 0.90 up $pcc $pcd
}

$ns at 10.0 "fim"

$ns run
