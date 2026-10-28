// Fails if any file git would commit looks like personal data or a secret.
// Runs in the pre-commit hook, `npm test` and CI. The repo is public: the only
// personal-looking data allowed is example.com addresses and 555 numbers.
import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";

const EMAIL = /[A-Za-z0-9._%+-]+@(?!example\.(com|org)\b)[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g;
const PHONE = /\(?\b\d{3}\)?[\s.-]\d{3}[\s.-]\d{4}\b/g;
const AWS_KEY = /\b(AKIA|ASIA)[A-Z0-9]{16}\b/g;
const AWS_ACCOUNT = /\b\d{12}\b/g;
const PRIVATE_KEY = /-----BEGIN [A-Z ]*PRIVATE KEY-----/g;
const API_TOKEN = /\b(sk-ant-[A-Za-z0-9_-]{20,}|gh[pousr]_[A-Za-z0-9]{30,}|xox[abp]-[A-Za-z0-9-]{20,})/g;
const ALLOWED_EMAILS = new Set(["noreply@anthropic.com"]);
const BLOCKED_NAMES = /(^|\/)(\.env(\..+)?|.+\.tfstate(\..+)?|.+\.tfvars|.+\.pem)$/;
const PHOTO = /\.(jpe?g|heic|png|webp)$/i;
const SKIP = new Set(["package-lock.json"]);

// Tracked + untracked-but-not-ignored files: exactly what `git add -A` could commit.
const files = execFileSync("git", ["ls-files", "-co", "--exclude-standard"], { encoding: "utf8" })
  .split("\n")
  .filter(Boolean);

const problems = [];
for (const file of files) {
  const name = file.split("/").pop();
  if (SKIP.has(name)) continue;
  if (BLOCKED_NAMES.test(file) && !file.endsWith(".env.example") && !file.endsWith("example.tfvars")) {
    problems.push(`${file}: secrets/state file`);
    continue;
  }
  if (PHOTO.test(file)) {
    if (!file.startsWith("web/public/")) problems.push(`${file}: photo outside web/public/ (personal media?)`);
    continue;
  }
  let text;
  try {
    text = readFileSync(file, "utf8");
  } catch {
    continue; // deleted in the working tree
  }
  for (const m of text.match(EMAIL) || []) if (!ALLOWED_EMAILS.has(m)) problems.push(`${file}: email "${m}"`);
  for (const m of text.match(PHONE) || []) if (!/555[\s.-]\d{4}/.test(m)) problems.push(`${file}: phone "${m}"`);
  for (const m of text.match(AWS_KEY) || []) problems.push(`${file}: AWS access key "${m.slice(0, 8)}…"`);
  for (const m of text.match(AWS_ACCOUNT) || []) problems.push(`${file}: 12-digit number "${m}" (AWS account ID?)`);
  for (const m of text.match(API_TOKEN) || []) problems.push(`${file}: API token "${m.slice(0, 8)}…"`);
  if (PRIVATE_KEY.test(text)) problems.push(`${file}: private key`);
  PRIVATE_KEY.lastIndex = 0;
}

if (problems.length) {
  console.error(`Privacy check FAILED — this repo is public:\n  ${problems.join("\n  ")}`);
  process.exit(1);
}
console.log(`privacy OK (${files.length} files)`);
