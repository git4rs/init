for i in `ls /alog/wallet-service/walletlogs/wallet-service*/wallet-service.log.2016-* | grep -v bz2`; do bzip2 $i; done

cd /alog/wallet-service/walletlogs/wallet-service1; mv *bz2 old_logs; rsync -a old_logs/* 10.140.31.35:/alog/10.140.31.76/wallet-service/walletlogs/wallet-service1/old_logs; rm -f old_logs/*


cd /alog/wallet-service/walletlogs/wallet-service2; mv *bz2 old_logs; rsync -a old_logs/* 10.140.31.35:/alog/10.140.31.76/wallet-service/walletlogs/wallet-service2/old_logs; rm -f old_logs/*
