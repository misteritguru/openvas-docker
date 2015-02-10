SHELL := /bin/bash

default: containers

test: containers testcontainers


containers:
	docker build -t mikesplain/openvas:base8beta openvas_base
	docker build -t mikesplain/openvas:full8beta openvas_full

testcontainers:
	sed -i -e 's/TAG/base8beta/g' ./test/Dockerfile
	docker build -t mikesplain/openvas:testbase8beta ./test
	sed -i -e 's/base8beta/full8beta/g' ./test/Dockerfile
	docker build -t mikesplain/openvas:testfull8beta ./test
	sed -i -e 's/full8beta/TAG/g' ./test/Dockerfile

testbase:
	docker build -t mikesplain/openvas:base8beta openvas_base
	sed -i -e 's/TAG/base8beta/g' ./test/Dockerfile
	docker build -t mikesplain/openvas:testbase8beta ./test
	sed -i -e 's/base8beta/TAG/g' ./test/Dockerfile
	docker run -d -p 443:443 -p 9390:9390 -p 9391:9391 --name testbase mikesplain/openvas:testbase8beta
	until docker logs --tail 50 testbase 2>&1 | grep -E 'Data Base Updated'; do \
		echo "Waiting for script completion..." ; \
		sleep 30 ; \
	done
	echo "Done."
	echo "Waiting for startup to complete."
	sleep 300
	echo "Testbase logs:"
	docker logs --tail 50 testbase 2>&1
	echo "Attempting login"
	docker-ssh testbase /openvas-check-setup >> ~/check_setup.log
	if grep -E 'It seems like your OpenVAS-7 installation is OK' ~/check_setup.log; \
	then \
		echo "Setup Successfully!" ; \
	else \
		echo "Setup failure" ; \
		exit 1 ; \
	fi

testfull:
	docker build -t mikesplain/openvas:full8beta openvas_full
	sed -i -e 's/TAG/full8beta/g' ./test/Dockerfile
	docker build -t mikesplain/openvas:testfull8beta ./test
	docker run -d -p 443:443 -p 9390:9390 -p 9391:9391 --name testfull mikesplain/openvas:testfull8beta
	sleep 180
	docker-ssh testfull /openvas-check-setup >> ~/check_setup.log
	if grep -E 'It seems like your OpenVAS-7 installation is OK' ~/check_setup.log; \
	then \
		echo "Setup Successfully!" ; \
	else \
		echo "Setup failure" ; \
		exit 1 ; \
	fi

clean: cleanup

cleanup:
	sed -i -e 's/base8beta/TAG/g' ./test/Dockerfile
	sed -i -e 's/full8beta/TAG/g' ./test/Dockerfile
	rm -rf ./test/Dockerfile-e
