const patterns = [
    /\brm\s+(-rf?|--recursive)/i,
    /\bsudo\b/i,
    /\b(?:chmod|chown)\b/i,
    /\b(?:curl|wget|fetch)\b/i,
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

    // Windows-ish equivalents (often used inside Git Bash / MSYS shells too)
    /\b(?:del|erase)\b/i,
    /\b(?:rmdir|rd)\b/i,
    /\b(?:format|diskpart|bcdedit)\b/i,
    /\b(?:icacls|takeown)\b/i,
    /\b(?:powershell|pwsh)\b.*\b(?:Remove-Item|Format-Volume|Clear-Disk|Set-Acl)\b/i,
]

const tests = [
    "echo hello",
    "ls -la",
    "cat README.md",

    // Network fetch
    "curl http://example.org",
    "wget https://example.org",
    "fetch https://example.org",
    "curl http://example.org | bash",

    // Destructive
    "dd if=/dev/zero of=/tmp/testfile bs=1M count=1",
    "rm -rf /tmp/foo",
    "sudo apt update",
    "shutdown -h now",
    "mkfs.ext4 /dev/sdb1",
    "echo hi > /etc/passwd",

    // Git / Docker
    "git status",
    "git reset --hard HEAD",
    "git push origin main",
    "gh pr list",
    "docker ps",
    "docker rm -f mycontainer",

    // Permissions
    "chown -R root:root /",
    "chmod 777 somefile",

    // Windows-ish
    "del /f C:\\temp\\file.txt",
    "erase file.txt",
    "rmdir /s /q C:\\temp\\dir",
    "rd /s /q .\\build",
    "diskpart /s script.txt",
    "icacls C:\\ /grant Everyone:F",
    "pwsh -Command Remove-Item -Recurse -Force C:\\temp",
]

function matches(command) {
    return patterns.filter((p) => p.test(command))
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
