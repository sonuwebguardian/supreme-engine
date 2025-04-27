# Supreme Engine

**Supreme Engine** is an automated reconnaissance tool designed for bug bounty hunters and penetration testers. It streamlines the process of gathering information about target domains, including subdomain enumeration, port scanning, wayback URL collection, and screenshot capture.

## 🚀 Features

- **Modular Design**: Each reconnaissance phase is handled by a separate script.
- **Customizable Execution**: Use `--skip-*` and `--only-*` flags to tailor the recon process.
- **Tool Installation**: Easily install required tools with the `tools-setup.sh` script.

## 🛠️ Installation

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/sonuwebguardian/supreme-engine.git
   cd supreme-engine
   ```

2. **Install Required Tools**:
   Ensure you have Go installed. Then run:
   ```bash
   bash tools-setup.sh
   ```

3. **Make Scripts Executable**:
   ```bash
   chmod +x main.sh recon.sh tools-setup.sh
   chmod +x modules/*.sh
   ```

## ⚙️ Usage

Run the reconnaissance process with:
```bash
bash recon.sh example.com
```

### Available Flags

- `--skip-subdomain`: Skip subdomain enumeration.
- `--skip-portscan`: Skip port scanning.
- `--skip-wayback`: Skip wayback URL collection.
- `--skip-screenshots`: Skip screenshot capture.
- `--only-subdomain`: Only perform subdomain enumeration.
- `--only-portscan`: Only perform port scanning.
- `--only-wayback`: Only perform wayback URL collection.
- `--only-screenshots`: Only perform screenshot capture.

**Note**: Only one `--only-*` flag can be used at a time.

Example:
```bash
bash main.sh -d example.com --only-subdomain
```

## 📁 Output

Results are saved in the `output/` directory, organized by domain:
```
output/
└── example.com/
    ├── subdomains/
    ├── portscan/
    ├── wayback/
    ├── screenshots/
    └── logs/
```

## 📝 Configuration

Edit the `config.yaml` file to customize tool paths and wordlists:
```yaml
wordlists:
  subdomain: "/path/to/wordlist.txt"

paths:
  subfinder: "/usr/local/bin/subfinder"
  naabu: "/usr/local/bin/naabu"
  gowitness: "/usr/local/bin/gowitness"
  waybackurls: "/usr/local/bin/waybackurls"
```

## 📌 Dependencies

- [subfinder](https://github.com/projectdiscovery/subfinder)
- [naabu](https://github.com/projectdiscovery/naabu)
- [gowitness](https://github.com/sensepost/gowitness)
- [waybackurls](https://github.com/tomnomnom/waybackurls)

Ensure these tools are installed and accessible in your system's PATH.

## 📄 License

This project is licensed under the MIT License.

---

Happy Hunting! 🕵️‍♂️
