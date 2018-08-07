import json
import re
from os.path import join, dirname, normpath
from subprocess import check_call, Popen, PIPE


class TerraformWorkspace:
    def __init__(self, working_directory: str, workspace_name: str) -> None:
        super().__init__()
        self.workspace_name = workspace_name
        self.working_directory = normpath(join(dirname(__file__), '..', working_directory))

    def __enter__(self):
        check_call('terraform init', cwd=self.working_directory)
        check_call('terraform workspace new ' + self.workspace_name, cwd=self.working_directory)
        return self

    def __exit__(self, type, value, tb):
        check_call('terraform workspace select ' + self.workspace_name, cwd=self.working_directory)
        check_call('terraform workspace select default', cwd=self.working_directory)
        check_call('terraform workspace delete ' + self.workspace_name, cwd=self.working_directory)


def test_01():
    with TerraformWorkspace('test_01_a', 'test-01-a') as ws_setup:
        check_call('terraform apply -auto-approve', cwd=ws_setup.working_directory)
        try:
            with open(join(ws_setup.working_directory, 'terraform.tfstate.d/test-01-a/terraform.tfstate'), 'r') as f:
                setup_state = json.load(f)
            resources = setup_state['modules'][0]['resources']
            load_balancer_arn = resources['aws_lb.default']['primary']['attributes']['arn']
            nginx_target_group_arn = resources['aws_lb_target_group.nginx']['primary']['attributes']['arn']

            with TerraformWorkspace('test_01_b', 'test-01-b') as ws_main:
                var_args = '-var "load_balancer_arn=' + load_balancer_arn + '" ' \
                           '-var "target_group_arn=' + nginx_target_group_arn + '"'
                process = Popen('terraform apply -auto-approve -no-color ' + var_args, cwd=ws_main.working_directory,
                                stdout=PIPE, stdin=PIPE)
                stdout, stderr = process.communicate()
                try:
                    assert process.returncode == 0
                    assert not stderr
                finally:
                    check_call('terraform destroy -force ' + var_args, cwd=ws_main.working_directory)
        finally:
            check_call('terraform destroy -force', cwd=ws_setup.working_directory)
