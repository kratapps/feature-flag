alias=lib
alias_packaging=kratapps-prod

scratch-org:
	sf org create scratch -a ${alias} -f config/project-scratch-def.json --duration-days 30
	sf project deploy start -o ${alias}

unit-test:
	sf apex run test -o ${alias} --code-coverage --test-level RunLocalTests --result-format human --wait 20
