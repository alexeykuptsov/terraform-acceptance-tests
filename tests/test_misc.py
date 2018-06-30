import json
from subprocess import check_call, Popen, PIPE


def test_01():
    check_call('terraform init', cwd='setup')
    check_call('terraform workspace new test-01-setup', cwd='setup')
    check_call('terraform apply -auto-approve', cwd='setup')

    with open('setup/terraform.tfstate.d/test-01-setup/terraform.tfstate', 'r') as f:
        setup_state = json.load(f)
    load_balancer_arn = setup_state['modules'][0]['resources']['aws_lb.default']['primary']['attributes']['arn']
    nginx_target_group_arn = setup_state['modules'][0]['resources']['aws_lb_target_group.nginx']['primary']['attributes']['arn']

    check_call('terraform init', cwd='test_01')
    check_call('terraform workspace new test-01-main', cwd='test_01')
    process = Popen('terraform apply -auto-approve -var "load_balancer_arn=' + load_balancer_arn + '" -var '
                    '"target_group_arn=' + nginx_target_group_arn + '"', cwd='test_01', stdout=PIPE, stdin=PIPE)
    stdout, stderr = process.communicate()

    try:
        assert process.returncode == 0
        assert not stderr
    finally:
        check_call('terraform workspace select test-01-main', cwd='test_01')
        check_call('terraform destroy -force -var load_balancer_arn=dummy -var target_group_arn=dummy', cwd='test_01')
        check_call('terraform workspace select default', cwd='test_01')
        check_call('terraform workspace delete test-01-main', cwd='test_01')

        check_call('terraform workspace select test-01-setup', cwd='setup')
        check_call('terraform destroy -force', cwd='setup')
        check_call('terraform workspace select default', cwd='setup')
        check_call('terraform workspace delete test-01-setup', cwd='setup')
