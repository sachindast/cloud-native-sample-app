#!/usr/bin/env python3

import argparse
import subprocess

def run_command(command):
    result = subprocess.run(
        command,
        capture_output=True,
        text=True
    )

    success = result.returncode == 0

    if success:
        return True, result.stdout.strip()
    else:
        return False, result.stderr.strip()

def status():
    print("Checking Cloud-Native DevOps Platform...")
    print()

    aws_ok, aws_message = run_command(
        ["aws", "sts", "get-caller-identity"]
    )

    aws_check = {
        "name": "AWS Authentication",
        "status": aws_ok,
        "message": aws_message
    }

    k8s_ok, k8s_message = run_command(
        ["kubectl", "cluster-info"]
    )

    k8s_check = {
        "name": "Kubernetes Cluster",
        "status": k8s_ok,
        "message": k8s_message
    }

    checks = [
        aws_check,
        k8s_check
    ]

    for check in checks:
        if check["status"]:
            print(f"✔ {check['name']}")
        else:
            print(f"✖ {check['name']}")
            print(f"  Reason: {check['message']}")

def main():
    parser = argparse.ArgumentParser(
        description="Cloud Native DevOps Platform Automation Toolkit"
    )

    parser.add_argument(
        "command",
        choices=["status"],
        help="Command to execute"
    )

    args = parser.parse_args()

    if args.command == "status":
        status()


if __name__ == "__main__":
    main()