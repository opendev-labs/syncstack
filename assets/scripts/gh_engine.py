#!/usr/bin/env python3
import sys
import os
import subprocess
import json
import requests
from datetime import datetime

class GHEngine:
    def __init__(self, workspace_root=None):
        if workspace_root:
            self.workspace_root = workspace_root
        else:
            # Default to a subfolder in user data if not provided
            self.workspace_root = os.path.expanduser("~/.gh-sync-data")
        
        self.snapshots_dir = os.path.join(self.workspace_root, "snapshots")
        if not os.path.exists(self.snapshots_dir):
            os.makedirs(self.snapshots_dir, exist_ok=True)

    def run_git(self, repo_path, args):
        try:
            result = subprocess.run(
                ["git", "-C", repo_path] + args,
                capture_output=True,
                text=True,
                check=False
            )
            return result
        except Exception as e:
            return None

    def get_repo_status(self, repo_path):
        if not os.path.exists(os.path.join(repo_path, ".git")):
            return {"exists": False}

        # 1. Current Branch
        res = self.run_git(repo_path, ["rev-parse", "--abbrev-ref", "HEAD"])
        branch = res.stdout.strip() if res and res.returncode == 0 else "main"

        # 2. Local Changes (Dirty Status)
        res = self.run_git(repo_path, ["status", "--porcelain"])
        changes = res.stdout.strip().split("\n") if res and res.stdout.strip() else []
        is_dirty = len(changes) > 0

        # 3. Ahead / Behind Status
        # Fetch first to get latest remote info
        self.run_git(repo_path, ["fetch", "--quiet"])
        res = self.run_git(repo_path, ["rev-list", "--left-right", "--count", f"HEAD...origin/{branch}"])
        ahead, behind = 0, 0
        if res and res.returncode == 0:
            parts = res.stdout.strip().split()
            if len(parts) == 2:
                ahead, behind = int(parts[0]), int(parts[1])

        # 4. Conflict Prediction
        risk = "low"
        if is_dirty and behind > 0:
            risk = "high"
        elif behind > 0:
            risk = "medium"

        return {
            "exists": True,
            "branch": branch,
            "is_dirty": is_dirty,
            "changes_count": len(changes),
            "ahead": ahead,
            "behind": behind,
            "risk": risk,
            "human_status": self._humanize_status(is_dirty, ahead, behind)
        }

    def _humanize_status(self, is_dirty, ahead, behind):
        if is_dirty: return "Uncommitted changes"
        if ahead > 0 and behind > 0: return f"Diverged ({ahead}↑ / {behind}↓)"
        if ahead > 0: return f"{ahead} commits ahead (Push needed)"
        if behind > 0: return f"{behind} commits behind (Pull needed)"
        return "Up to date"

    def create_snapshot(self, repo_path, repo_name):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        snapshot_branch = f"gh-sync-backup-{timestamp}"
        
        # We create a new branch from current HEAD as a safety backup
        res = self.run_git(repo_path, ["branch", snapshot_branch])
        if res and res.returncode == 0:
            return snapshot_branch
        return None

    def sync_repo(self, repo_path, repo_name, remote_url, token, strategy="pull"):
        status = self.get_repo_status(repo_path)
        
        # 1. Handle non-existent repo (Clone)
        if not status["exists"]:
            auth_url = remote_url.replace("https://", f"https://{token}@")
            os.makedirs(os.path.dirname(repo_path), exist_ok=True)
            res = subprocess.run(["git", "clone", auth_url, repo_path], capture_output=True, text=True)
            if res.returncode == 0:
                return {"success": True, "operation": "clone", "message": "Repository cloned successfully"}
            else:
                return {"success": False, "message": f"Clone failed: {res.stderr}"}

        # 2. Safety Snapshot
        snapshot_id = self.create_snapshot(repo_path, repo_name)

        # 3. Execute Sync Strategy
        try:
            if strategy == "reset":
                # Hard reset to remote
                self.run_git(repo_path, ["fetch", "origin"])
                res = self.run_git(repo_path, ["reset", "--hard", f"origin/{status['branch']}"])
                if res.returncode != 0: raise Exception(res.stderr)
            
            elif strategy == "rebase":
                # Rebase local on top of remote
                res = self.run_git(repo_path, ["pull", "--rebase", "origin", status["branch"]])
                if res.returncode != 0: raise Exception(res.stderr)
            
            else: # default pull
                # Standard merge pull
                res = self.run_git(repo_path, ["pull", "origin", status["branch"]])
                if res.returncode != 0: raise Exception(res.stderr)

            return {
                "success": True, 
                "operation": strategy, 
                "message": "Sync completed successfully",
                "snapshot": snapshot_id
            }

        except Exception as e:
            return {
                "success": False,
                "message": f"Sync failed: {str(e)}",
                "snapshot": snapshot_id,
                "suggestion": "A backup branch was created. You can restore your work if needed."
            }

    # API Wrappers (Moved from gh_api.py)
    def validate_token(self, username, token):
        try:
            response = requests.get(
                'https://api.github.com/user',
                headers={'Authorization': f'token {token}', 'Accept': 'application/vnd.github.v3+json'},
                timeout=10
            )
            if response.status_code == 200:
                user_data = response.json()
                if user_data['login'].lower() == username.lower():
                    return {"success": True, "user": user_data}
            return {"success": False, "message": "Invalid token or username mismatch"}
        except Exception as e:
            return {"success": False, "message": str(e)}

    def get_user_repos(self, token):
        try:
            response = requests.get(
                'https://api.github.com/user/repos?per_page=100&sort=updated',
                headers={'Authorization': f'token {token}', 'Accept': 'application/vnd.github.v3+json'},
                timeout=10
            )
            if response.status_code == 200:
                return {"success": True, "repos": response.json()}
            return {"success": False, "message": f"GitHub API Error {response.status_code}: {response.text}"}
        except Exception as e:
            return {"success": False, "message": f"Connection Error: {str(e)}"}

    def search_repos(self, token, query):
        try:
            response = requests.get(
                f'https://api.github.com/search/repositories?q={query}',
                headers={'Authorization': f'token {token}', 'Accept': 'application/vnd.github.v3+json'},
                timeout=10
            )
            if response.status_code == 200:
                return {"success": True, "repos": response.json().get('items', [])}
            return {"success": False, "message": f"Search Error {response.status_code}"}
        except Exception as e:
            return {"success": False, "message": str(e)}

    def batch_sync(self, token, repos_list, strategy="pull"):
        results = []
        for repo in repos_list:
            # repo is dict with fullName, cloneUrl
            name = repo['fullName']
            url = repo['cloneUrl']
            path = os.path.join(self.workspace_root, name)
            res = self.sync_repo(path, name, url, token, strategy)
            results.append({"repo": name, "result": res})
        return {"success": True, "results": results}

if __name__ == "__main__":
    engine = GHEngine()
    
    if len(sys.argv) < 2:
        print(json.dumps({"success": False, "message": "Missing command"}))
        sys.exit(1)

    cmd = sys.argv[1]
    
    try:
        if cmd == "validate":
            print(json.dumps(engine.validate_token(sys.argv[2], sys.argv[3])))
        elif cmd == "get_repos":
            print(json.dumps(engine.get_user_repos(sys.argv[2])))
        elif cmd == "search_repos":
            print(json.dumps(engine.search_repos(sys.argv[2], sys.argv[3])))
        elif cmd == "get_status":
            print(json.dumps(engine.get_repo_status(sys.argv[2])))
        elif cmd == "sync":
            # sync <path> <name> <url> <token> <strategy>
            if len(sys.argv) < 6:
                print(json.dumps({"success": False, "message": "Missing arguments for sync"}))
            else:
                path, name, url, token = sys.argv[2:6]
                strategy = sys.argv[6] if len(sys.argv) > 6 else "pull"
                print(json.dumps(engine.sync_repo(path, name, url, token, strategy)))
        elif cmd == "batch_sync":
            # batch_sync <token> <repos_json> <strategy>
            token = sys.argv[2]
            repos_list = json.loads(sys.argv[3])
            strategy = sys.argv[4] if len(sys.argv) > 4 else "pull"
            print(json.dumps(engine.batch_sync(token, repos_list, strategy)))
        else:
            print(json.dumps({"success": False, "message": f"Unknown command: {cmd}"}))
    except Exception as e:
        print(json.dumps({"success": False, "message": f"Engine runtime error: {str(e)}"}))
