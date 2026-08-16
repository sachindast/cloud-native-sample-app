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


def create_check(name, command):
    success, message = run_command(command)

    return {
        "name": name,
        "status": success,
        "message": message
    }


def get_kubernetes_nodes():
    """Return Kubernetes node health as structured data."""

    node_ok, node_output = run_command(
        ["kubectl", "get", "nodes"]
    )

    if not node_ok:
        return {
            "healthy": False,
            "nodes": [],
            "error": node_output
        }

    lines = node_output.splitlines()

    nodes = []
    all_nodes_ready = True

    # Skip the header line
    for line in lines[1:]:
        parts = line.split()

        if len(parts) < 2:
            continue

        node_name = parts[0]
        node_status = parts[1]

        nodes.append(
            {
                "name": node_name,
                "status": node_status
            }
        )

        if node_status != "Ready":
            all_nodes_ready = False

    return {
        "healthy": all_nodes_ready,
        "nodes": nodes
    }


def status():
    print("Checking Cloud-Native DevOps Platform...")
    print()

    # AWS Check
    aws_check = create_check(
        "AWS Authentication",
        ["aws", "sts", "get-caller-identity"]
    )

    # Kubernetes Connectivity Check
    k8s_check = create_check(
        "Kubernetes Cluster",
        ["kubectl", "cluster-info"]
    )

    # Kubernetes Node Check
    node_result = get_kubernetes_nodes()

    # Argo CD Namespace Check
    argocd_check = create_check(
        "Argo CD Namespace",
        ["kubectl", "get", "namespace", "argocd"]
    )

    # Argo CD Pod Check
    argocd_pod_ok, argocd_pod_output = run_command(
        ["kubectl", "get", "pods", "-n", "argocd"]
    )

    # Argo CD Application Check
    argocd_app_ok, argocd_app_output = run_command(
        ["kubectl", "get", "applications", "-n", "argocd"]
    )

    # Display basic platform checks
    checks = [
        aws_check,
        k8s_check,
        argocd_check
    ]

    for check in checks:
        if check["status"]:
            print(f"✔ {check['name']}")
        else:
            print(f"✖ {check['name']}")
            print(f"  Reason: {check['message']}")

    # Kubernetes Node Status
    print()
    print("Kubernetes Nodes")
    print("----------------")

    all_nodes_ready = node_result["healthy"]

    if node_result["nodes"]:
        for node in node_result["nodes"]:
            if node["status"] == "Ready":
                print(f"✔ {node['name']}: Ready")
            else:
                print(f"✖ {node['name']}: {node['status']}")
    else:
        print("✖ Unable to retrieve Kubernetes nodes")
        if "error" in node_result:
            print(f"  Reason: {node_result['error']}")

    print()

    if all_nodes_ready and node_result["nodes"]:
        print("✔ Overall Node Health: HEALTHY")
    else:
        print("✖ Overall Node Health: UNHEALTHY")

    # Argo CD Pod Status
    print()
    print("Argo CD Pods")
    print("------------")

    all_argocd_pods_healthy = False

    if argocd_pod_ok:
        lines = argocd_pod_output.splitlines()

        all_argocd_pods_healthy = True

        # Skip the header line
        for line in lines[1:]:
            parts = line.split()

            if len(parts) < 3:
                continue

            pod_name = parts[0]
            ready_status = parts[1]
            pod_status = parts[2]

            if ready_status == "1/1" and pod_status == "Running":
                print(f"✔ {pod_name}: Running")
            else:
                print(
                    f"✖ {pod_name}: "
                    f"READY={ready_status}, STATUS={pod_status}"
                )
                all_argocd_pods_healthy = False

        print()

        if all_argocd_pods_healthy:
            print("✔ Overall Argo CD Pod Health: HEALTHY")
        else:
            print("✖ Overall Argo CD Pod Health: UNHEALTHY")

    else:
        print("✖ Unable to retrieve Argo CD pods")
        print(f"  Reason: {argocd_pod_output}")

    # Argo CD Application Status
    print()
    print("Argo CD Applications")
    print("--------------------")

    all_applications_healthy = False

    if argocd_app_ok:
        lines = argocd_app_output.splitlines()

        all_applications_healthy = True

        # Skip the header line
        for line in lines[1:]:
            parts = line.split()

            if len(parts) < 3:
                continue

            app_name = parts[0]
            sync_status = parts[1]
            health_status = parts[2]

            if sync_status == "Synced" and health_status == "Healthy":
                print(
                    f"✔ {app_name}: "
                    f"SYNC={sync_status}, HEALTH={health_status}"
                )
            else:
                print(
                    f"✖ {app_name}: "
                    f"SYNC={sync_status}, HEALTH={health_status}"
                )
                all_applications_healthy = False

        print()

        if all_applications_healthy:
            print("✔ Overall Argo CD Application Health: HEALTHY")
        else:
            print("✖ Overall Argo CD Application Health: UNHEALTHY")

    else:
        print("✖ Unable to retrieve Argo CD applications")
        print(f"  Reason: {argocd_app_output}")

    # Overall GitOps Health
    print()
    print("GitOps Platform Health")
    print("----------------------")

    gitops_healthy = (
        argocd_check["status"]
        and all_argocd_pods_healthy
        and all_applications_healthy
    )

    if gitops_healthy:
        print("✔ Overall GitOps Platform: HEALTHY")
    else:
        print("✖ Overall GitOps Platform: UNHEALTHY")


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