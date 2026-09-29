function vault -d "Toggle the encrypted gocryptfs vault (lock if mounted, unlock if not)"
    # Usage: vault
    # Encrypted data lives in ~/.vault and is mounted at ~/vault.
    # When unlocking, the vault auto-locks after 15 minutes idle.
    # Prints "locked" or "unlocked" on success.
    if mountpoint -q ~/vault
        fusermount3 -u ~/vault; and echo locked
    else
        gocryptfs -idle 15m ~/.vault ~/vault; and echo unlocked
    end
end
