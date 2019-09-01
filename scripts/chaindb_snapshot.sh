NETWORK=$1
CURRENCY=$2
BLOCK=$3


if [ "$#" -ne 3 ]; then
    echo "usage: $0 NETWORK CURRENCY BLOCK" 1>&2
    exit 1
fi

CONTRACT=eosio.token


mysql chaindb --execute="create table ${NETWORK}_ALLACC_${BLOCK} as select distinct account_name from USERRES where network='${NETWORK}'"


mysql chaindb --execute="create table ${NETWORK}_BAL_${BLOCK} AS select BALANCES.account_name, BALANCES.amount from BALANCES inner join (select network, max(block_num) as bn, account_name, contract, currency from BALANCES where network='${NETWORK}' and contract='${CONTRACT}' and currency='${CURRENCY}' and block_num <= ${BLOCK} group by account_name) x on BALANCES.network=x.network and BALANCES.account_name=x.account_name and BALANCES.contract=x.contract and BALANCES.currency=x.currency and  BALANCES.block_num=x.bn"


mysql chaindb --execute="create table ${NETWORK}_STAKE_${BLOCK} AS select DELBAND.del_from as account_name, sum(DELBAND.cpu_weight) as cpu_weight, sum(DELBAND.net_weight) as net_weight from DELBAND inner join (select network, max(block_num) as bn, del_from from DELBAND where network='${NETWORK}' and block_num <= ${BLOCK} group by del_from) x on DELBAND.network=x.network and DELBAND.del_from=x.del_from and DELBAND.block_num=x.bn group by DELBAND.del_from"


mysql chaindb --execute="create table ${NETWORK}_REXFUND_${BLOCK} AS select REXFUND.account_name, REXFUND.balance from REXFUND inner join (select network, max(block_num) as bn, account_name from REXFUND where network='${NETWORK}' and block_num <= ${BLOCK} group by account_name) x on REXFUND.network=x.network and REXFUND.account_name=x.account_name and REXFUND.block_num=x.bn"


mysql chaindb --execute="create table ${NETWORK}_REXBAL_${BLOCK} AS select REXBAL.account_name, REXBAL.vote_stake from REXBAL inner join (select network, max(block_num) as bn, account_name from REXBAL where network='${NETWORK}' and block_num <= ${BLOCK} group by account_name) x on REXBAL.network=x.network and REXBAL.account_name=x.account_name and REXBAL.block_num=x.bn"


mysql chaindb --execute="create index ${NETWORK}_${BLOCK}_ix0 on ${NETWORK}_ALLACC_${BLOCK}(account_name)"
mysql chaindb --execute="create index ${NETWORK}_${BLOCK}_ix1 on ${NETWORK}_BAL_${BLOCK}(account_name)"
mysql chaindb --execute="create index ${NETWORK}_${BLOCK}_ix2 on ${NETWORK}_STAKE_${BLOCK}(account_name)"
mysql chaindb --execute="create index ${NETWORK}_${BLOCK}_ix3 on ${NETWORK}_REXFUND_${BLOCK}(account_name)"
mysql chaindb --execute="create index ${NETWORK}_${BLOCK}_ix4 on ${NETWORK}_REXBAL_${BLOCK}(account_name)"


mysql chaindb --execute="create table ${NETWORK}_TOTALS_${BLOCK} AS select ${NETWORK}_ALLACC_${BLOCK}.account_name, IFNULL(cpu_weight,0)/10000 as cpu_stake, IFNULL(net_weight,0)/10000 as net_stake, IFNULL(${NETWORK}_BAL_${BLOCK}.amount,0)/10000 as liquid, IFNULL(${NETWORK}_REXFUND_${BLOCK}.balance,0)/10000 as rex_fund, IFNULL(${NETWORK}_REXBAL_${BLOCK}.vote_stake,0)/10000 as rex_bal, (IFNULL(cpu_weight,0)+IFNULL(net_weight,0)+IFNULL(${NETWORK}_BAL_${BLOCK}.amount,0)+IFNULL(${NETWORK}_REXFUND_${BLOCK}.balance,0)+IFNULL(${NETWORK}_REXBAL_${BLOCK}.vote_stake,0))/10000 as total from ${NETWORK}_ALLACC_${BLOCK} left outer join ${NETWORK}_STAKE_${BLOCK} using(account_name) left outer join ${NETWORK}_BAL_${BLOCK} using(account_name) left outer join ${NETWORK}_REXFUND_${BLOCK} using(account_name) left outer join ${NETWORK}_REXBAL_${BLOCK} using(account_name)"


