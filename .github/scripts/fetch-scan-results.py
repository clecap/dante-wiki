import requests
import json
import os

def fetch_vulnerability_scan(repo_name, tag, token):
    url = f"https://hub.docker.com/api/v2/repositories/{repo_name}/tags/{tag}/scan/"
    headers = {"Authorization": f"JWT {token}"}
    response = requests.get(url, headers=headers)
    print ("URL: ", url)
    print ("Response ", response)
    json = response.json()
    return json

def parse_scan_results(scan_results):
    vulnerabilities = scan_results.get("vulnerabilities", [])
    severity_count = {"low": 0, "medium": 0, "high": 0, "critical": 0}

    for vulnerability in vulnerabilities:
        severity = vulnerability.get("severity")
        if severity in severity_count:
            severity_count[severity] += 1

    return severity_count

def main():
    repo_name = os.getenv('DOCKER_HUB_REPO')
    tag = os.getenv('DOCKER_HUB_TAG')
    token = os.getenv('DOCKER_HUB_TOKEN')

    print("Repo:", repo_name)
    print("Tag:", tag)
    print("Token:", token)
    
    scan_results = fetch_vulnerability_scan(repo_name, tag, token)
    severity_count = parse_scan_results(scan_results)

    badge_data = {
        "schemaVersion": 1,
        "label": "vulnerabilities",
        "message": f"high: {severity_count['high']}, medium: {severity_count['medium']}, low: {severity_count['low']}",
        "color": "red" if severity_count['high'] > 0 else "green"
    }

    with open('scan_results.json', 'w') as f:
        json.dump(badge_data, f)

if __name__ == "__main__":
    main()
