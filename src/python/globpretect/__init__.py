import os
import socket
import subprocess
from typing import List, Dict, Optional


class VPNManager:
    """Manages VPN connections and routing for Ollama access."""

    PORTS = {"granite": 55077, "think": 55088, "qwen": 66044, "code": 66033}

    def __init__(self):
        self.ssh_key = os.path.expanduser("~/projects/GlobPretect/id_ed25519_sweeden")
        self.hpcc_host = "sweeden@login.hpcc.ttu.edu"

    def check_port(self, port: int, host: str = "127.0.0.1") -> bool:
        """Check if a port is accessible."""
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(1)
        try:
            result = sock.connect_ex((host, port))
            return result == 0
        finally:
            sock.close()

    def check_vpn_active(self) -> List[int]:
        """Check which Ollama ports are accessible."""
        active = []
        for name, port in self.PORTS.items():
            if self.check_port(port):
                active.append(port)
        return active

    def all_ports_active(self) -> bool:
        """Check if all Ollama ports are accessible."""
        active = self.check_vpn_active()
        return len(active) == len(self.PORTS)

    def establish_tunnel(
        self, local_port: int, remote_port: int, remote_host: str = "localhost"
    ) -> subprocess.Popen:
        """Establish SSH tunnel for port forwarding."""
        cmd = [
            "ssh",
            "-i",
            self.ssh_key,
            "-L",
            f"{local_port}:{remote_host}:{remote_port}",
            "-N",
            "-f",
            self.hpcc_host,
        ]
        return subprocess.Popen(cmd)

    def start_ollama_tunnels(self) -> Dict[str, subprocess.Popen]:
        """Start all Ollama port tunnels."""
        tunnels = {}
        for name, port in self.PORTS.items():
            tunnels[name] = self.establish_tunnel(port, port)
        return tunnels

    def test_hpcc_connection(self) -> bool:
        """Test SSH connection to HPCC."""
        try:
            result = subprocess.run(
                [
                    "ssh",
                    "-i",
                    self.ssh_key,
                    "-o",
                    "BatchMode=yes",
                    "-o",
                    "ConnectTimeout=5",
                    self.hpcc_host,
                    "echo",
                    "ok",
                ],
                capture_output=True,
                text=True,
                timeout=10,
            )
            return result.returncode == 0 and "ok" in result.stdout
        except:
            return False

    def get_status(self) -> Dict:
        """Get comprehensive VPN and connection status."""
        return {
            "ollama_ports": self.check_vpn_active(),
            "all_active": self.all_ports_active(),
            "hpcc_reachable": self.test_hpcc_connection(),
            "ssh_key_exists": os.path.exists(self.ssh_key),
        }
