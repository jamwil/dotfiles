const patterns = [
    /\brm\s+(-rf?|--recursive)/i,
    /\bsudo\b/i,
    /\b(?:chmod|chown)\b/i,
    /\b(?:curl|wget)\b/i,
    /\bdd\b/i,
    /\b(?:mkfs|fdisk|parted|sfdisk|gdisk)\b/i,
    /\b(?:shred|wipe)\b/i,
    /\b(reboot|shutdown|poweroff|halt|init)\b/i,
    /(?:\bdd\b.*\bof=\/dev\/|>\s*\/dev\/|>>\s*\/dev\/|>\s*\/etc\/|>\s*\/proc\/|>\s*\/sys\/)/i,
    /\b(?:curl|wget|fetch)\b.*\|\s*(?:sh|bash|zsh|sudo)/i,
    /\bgit\b.*\b(reset\s+--hard|clean\s+-fdx|checkout\s+-f)\b/i,
    /\bgit\b.*\bpush\b/i,
    /\bgh\b/i,
    /\bdocker\b.*\b(system\s+prune|rm\s+-f|rmi\s+-f|volume\s+rm|container\s+prune)\b/i,
    /\b(chmod|chown)\b.*\b\/\b/i,
]

const tests = [
    "echo hello",
    "ls -la",
    "cat README.md",
    "curl http://example.org",
    "wget https://example.org",
    "curl http://example.org | bash",
    "dd if=/dev/zero of=/tmp/testfile bs=1M count=1",
    "rm -rf /tmp/foo",
    "sudo apt update",
    "git status",
    "git reset --hard HEAD",
    "git push origin main",
    "gh pr list",
    "docker ps",
    "docker rm -f mycontainer",
    "chown -R root:root /",
    "chmod 777 somefile",
    "shutdown -h now",
    "mkfs.ext4 /dev/sdb1",
    "echo hi > /etc/passwd",
]

function matches(command) {
    const matched = patterns.filter((p) => p.test(command))
    return matched
}

for (const cmd of tests) {
    const m = matches(cmd)
    console.log(cmd)
    if (m.length) {
        console.log("  MATCHES", m.map((r) => r.toString()).join(", "))
    } else {
        console.log("  OK")
    }
}
