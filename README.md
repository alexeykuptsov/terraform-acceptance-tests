# Alexey Kuptsov's Terraform Acceptance Tests

Here I reproduce erroneous looking behavior of HashiCorp Terraform.

## Working Copy Setup

1. Ensure that your default Python version is at least 3.6:

```console
python --version
```

2. Create a local virtual environment that is configured so that PyCharm uses it as the Python interpreter for this
project:

```console
python -m venv venv
```

3. If you don't see `(venv)` in the beginning of a command line in PyCharm Terminal, restart the Terminal tool.

## Upgrade Dependencies

```console
pip install -U -r requirements.txt
```

## Test

```console
pytest tests
```
