#!/bin/sh

threads=$(echo $1 | cut -d '/' -f 1)
clients=$(echo $1 | cut -d '/' -f 2)
keymaximum=$(echo $1 | cut -d '/' -f 3)
keyminimum=$(echo $1 | cut -d '/' -f 4)
data_size=$(echo $1 | cut -d '/' -f 5) 
protocol=$(echo $1 | cut -d '/' -f 6) # memcache_text/ redis
client_mode=$(echo $1 | cut -d '/' -f 7 | cut -d '(' -f 1)
requests=$((keymaximum/(clients*threads)))
key_median=$(((keymaximum-keyminimum)/2))

# define server IP(현재client의IP를 확인해서)
server=$(hostname -I | tr -d '[:space:]')
case ${server} in
10.34.93.160) remote="11618";; # server: m001 & client: m002
10.34.91.143) remote="11617";; # server: m002 & client: m001
esac
# check account
account=$(pwd | cut -d '/' -f 3)
port=$2
#read client_mode
case $client_mode in
1) cli_mode="[1] Insertion operation"
C_command="ssh -T persistence@211.249.63.38 -p ${remote} \
/home/${account}/memtier_benchmark/memtier_benchmark -s ${server} -p ${port} \
--protocol=${protocol} --threads=${threads} --clients=${clients} \
--data-size=${data_size} --key-pattern=P:P --key-minimum=${keyminimum} --key-maximum=${keymaximum} \
--ratio=1:0 --requests=${requests} --print-percentiles=90,95,99" ;;

2) cli_mode="[2] Retrieve Data in uniform Random"
C_command="ssh -T persistence@211.249.63.38 -p ${remote} \
/home/${account}/memtier_benchmark/memtier_benchmark -s ${server} -p ${port} \
--protocol=${protocol} --threads=${threads} --clients=${clients} --key-pattern=R:R \
--distinct-client-seed --randomize --key-minimum=${keyminimum} --key-maximum=${keymaximum} \
--ratio=0:1 --requests=${requests} --print-percentiles=90,95,99" ;;

3) cli_mode="[3] Retrieve Data in Gaussian distribution (longtail)"
C_command="ssh -t persistence@211.249.63.38 -p ${remote} \
/home/${account}/memtier_benchmark/memtier_benchmark -s ${server} -p ${port} \
--protocol=${protocol} --threads=${threads} --clients=${clients} --key-pattern=G:G \
--distinct-client-seed --randomize --key-minimum=${keyminimum} --key-maximum=${keymaximum} \
--key-median=${key_median} --key-stddev=7800000 --ratio=0:1 --requests=${requests} \
--print-percentiles=90,95,99" ;;

4) cli_mode="[4] Insertion & Retrieve Data - Random (1:9)"
C_command="ssh -t persistence@211.249.63.38 -p ${remote} \
/home/${account}/memtier_benchmark/memtier_benchmark -s ${server} -p ${port} \
--protocol=${protocol} --threads=${threads} --clients=${clients} --data-size=${data_size} \
--key-pattern=P:P --distinct-client-seed --randomize --key-minimum=${keyminimum} \
--key-maximum=${keymaximum} --ratio=1:9 --requests=${requests} \
--print-percentiles=90,95,99" ;;

5) cli_mode="[4] Insertion & Retrieve Data - Random (3:7)"
C_command="ssh -t persistence@211.249.63.38 -p ${remote} \
/home/${account}/memtier_benchmark/memtier_benchmark -s ${server} -p ${port} \
--protocol=${protocol} --threads=${threads} --clients=${clients} --data-size=${data_size} \
--key-pattern=P:P --distinct-client-seed --randomize --key-minimum=${keyminimum} \
--key-maximum=${keymaximum} --ratio=3:7 --requests=${requests} \
--print-percentiles=90,95,99" ;;

6) cli_mode="[4] Insertion & Retrieve Data - Random (5:5)"
C_command="ssh -t persistence@211.249.63.38 -p ${remote} \
/home/${account}/memtier_benchmark/memtier_benchmark -s ${server} -p ${port} \
--protocol=${protocol} --threads=${threads} --clients=${clients} --data-size=${data_size} \
--key-pattern=P:P --distinct-client-seed --randomize --key-minimum=${keyminimum} \
--key-maximum=${keymaximum} --ratio=5:5 --requests=${requests} \
--print-percentiles=90,95,99" ;;

7) cli_mode="[5] Insertion & Retrieve Data - longtail (1:9)"
C_command="ssh -t persistence@211.249.63.38 -p ${remote} \
/home/${account}/memtier_benchmark/memtier_benchmark -s ${server} -p ${port} \
--protocol=${protocol} --threads=${threads} --clients=${clients} --data-size=${data_size} \
--key-pattern=G:G --distinct-client-seed --randomize --key-minimum=${keyminimum} \
--key-maximum=${keymaximum} --key-median=${key_median} --key-stddev=7800000 \
--ratio=1:9 --requests=${requests} --print-percentiles=90,95,99" ;;

8) cli_mode="[5] Insertion & Retrieve Data - longtail (3:7)"
C_command="ssh -t persistence@211.249.63.38 -p ${remote} \
/home/${account}/memtier_benchmark/memtier_benchmark -s ${server} -p ${port} \
--protocol=${protocol} --threads=${threads} --clients=${clients} --data-size=${data_size} \
--key-pattern=G:G --distinct-client-seed --randomize --key-minimum=${keyminimum} \
--key-maximum=${keymaximum} --key-median=${key_median} --key-stddev=7800000 \
--ratio=3:7 --requests=${requests} --print-percentiles=90,95,99" ;;

9) cli_mode="[5] Insertion & Retrieve Data - longtail (5:5)"
C_command="ssh -t persistence@211.249.63.38 -p ${remote} \
/home/${account}/memtier_benchmark/memtier_benchmark -s ${server} -p ${port} \
--protocol=${protocol} --threads=${threads} --clients=${clients} --data-size=${data_size} \
--key-pattern=G:G --distinct-client-seed --randomize --key-minimum=${keyminimum} \
--key-maximum=${keymaximum} --key-median=${key_median} --key-stddev=7800000 \
--ratio=5:5 --requests=${requests} --print-percentiles=90,95,99" ;;
esac

echo -e "* CLIENT CMD: $cli_mode *\n$C_command\n"
${C_command} &>> "memtier.log" &
