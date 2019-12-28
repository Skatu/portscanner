#!/bin/bash
shutDown(){
	echo "A terminar programa..."
	sleep 1
	exit 1
}

option1=$1 #numero porto (-n) ou ficheiro (-f)
param1=$2 #numero ou ficheiro (.txt)
option2=$3 #ficheiro (-h)
ipFile=$4 #ficheiro (.txt)
USAGE="USO: $0  < [ -n numero ] [ -f ficheiro ] > < -h ficheiro >"

#Verificar se foram inseridos o número correto de parâmetros
if [ $# -ne 4 ];then
	echo "Número incorreto de parâmetros inseridos."
	echo $USAGE
	shutDown
fi

#Permitir só as opções -n e -f para o 1º parâmetro
case "$1" in
	-n ) ;; #echo "Inserido um número";;
	-f ) ;; #echo "Inserido um ficheiro";;
	*)   echo "Opção 1 inválida."
		 echo $USAGE
		 shutDown ;;
esac

#Se o primeiro parâmetro for um número, verificar se é na verdade um número
if [ "$1" = "-n" ];then
	number=$(echo $param1 | grep -E "^[0-9]+$")
	if [ -z "$number" ];then
		echo "Parâmetro 1 inválido. Não foi inserido um número."
		echo $USAGE
		shutDown
	#verificar se número tem um valor válido para porto
	elif [ $param1 -lt 1 ] || [ $param1 -gt 65535 ];then
		echo "Inserir número entre 1 e 65535 no parâmetro 1."
		shutDown
	fi
fi

#Escolhido a opção -f para o 1º parâmetro, verificar se é ficheiro
if [ "$1" = "-f" ];then
	if [ ! -f "$2" ];then
		echo "Não foi inserido um ficheiro como parâmetro 1."
		echo $USAGE
		shutDown
	fi
fi

#Se a opção para o 2º parâmetro não for -h, terminar programa
if [ "$3" != "-h" ];then
	echo "Opção 2 inválida."
	echo $USAGE
	shutDown
fi
if [ ! -f "$4" ];then
	echo "Parâmetro 2 não é ficheiro."
	echo $USAGE
	shutDown
fi

#Criar ficheiro scan_report.txt. Caso exista, eliminá-lo e criar um novo.
if [ -f "scan_report.txt" ];then
	rm scan_report.txt
fi
#Para melhor organizar a informação no ficheiro	scan_report.txt,
#vai-se escrever em primeiro os portos ativos, depois os inativos
#e os inválidos. Os ativos são escritos diretamente no ficheiros.
#Os restantes (inativos e inválidos) são escritos num ficheiro temporário correspondente
#( inactivePorts.tmp e invalidPorts.tmp,respetivamente )
#e depois a informação desses ficheiros é escrita no scan_report.txt
touch scan_report.txt
touch inactivePorts.tmp
touch invalidPorts.tmp

echo "Portos Ativos" > scan_report.txt
#Verrifica os vários portos
if [ "$1" = -f ];then
	#Verifica cada porto do ip caso a opçao -f tenha sido usada para o parametro 1
	for host in $(cat $4);do
		for port in $(cat $2);do
			if [ $port -lt 1 ] || [ $port -gt 65535 ];then
				echo "Port: $port é inválido."
				echo "Port: $port é inválido.">>invalidPorts.tmp
				continue
			fi
			result=$(nc -zvw 1 $host $port 2>&1 | grep succeeded)
			# se result estiver vazia, então o porto está inativo
			if [ -z "$result" ];then
				echo "Port: $port está inativo no host $host"
				echo "Port: $port está inativo no host $host">>inactivePorts.tmp
			else
				echo "Port: $port está ativo no host $host"
				echo "Port: $port está ativo no host $host">>scan_report.txt
			fi
		done
	done	
else
	#Verifica cada porto do ip caso a opçao -n tenha sido usada para o parâmetro 1
	for host in $(cat $4);do
		result=$(nc -zvw 1 $host $2 2>&1 | grep succeeded)
		if [ -z "$result" ];then
			echo "Port: $2 está inativo no host $host"
			echo "Port: $2 está inativo no host $host">>inactivePorts.tmp
		else
			echo "Port: $2 está ativo no host $host"
			echo "Port: $2 está ativo no host $host">>scan_report.txt
		fi
	done
fi

#Escrever os portos inativos e inválidos no ficheiro scan_report.txt.
#Após a escrita, ambos os ficheiros inactivePorts.tmp e invalidPorts.tmp
#são eliminados
echo "Portos Inativos" >>scan_report.txt
cat inactivePorts.tmp >>scan_report.txt
rm inactivePorts.tmp

echo "Portos Inválidos" >>scan_report.txt
cat invalidPorts.tmp>>scan_report.txt
rm invalidPorts.tmp