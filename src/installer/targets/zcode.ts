/**
 * ZCode target.
 *
 * ZCode reads MCP servers from `./.mcp.json` (project-local) using the
 * same `mcpServers.<name>` shape as Claude Code. The config format is
 * standard JSON (with JSONC comment support).
 *
 *   - MCP server entry to `~/.zcode/.mcp.json` (global) or
 *     `./.mcp.json` (local).
 *   - No permissions concept — ZCode does not use a settings.json.
 *   - No instructions file — ZCode does not read CLAUDE.md/AGENTS.md.
 */

import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';
import {
  AgentTarget,
  DetectionResult,
  InstallOptions,
  Location,
  WriteResult,
} from './types';
import {
  getMcpServerConfig,
  jsonDeepEqual,
  readJsonFile,
  writeJsonFile,
} from './shared';

function configDir(loc: Location): string {
  return loc === 'global'
    ? path.join(os.homedir(), '.zcode')
    : process.cwd();
}

function mcpJsonPath(loc: Location): string {
  // global → ~/.zcode/.mcp.json
  // local  → ./.mcp.json
  return loc === 'global'
    ? path.join(os.homedir(), '.zcode', '.mcp.json')
    : path.join(process.cwd(), '.mcp.json');
}

class ZCodeTarget implements AgentTarget {
  readonly id = 'zcode' as const;
  readonly displayName = 'ZCode';
  readonly docsUrl = 'https://zcode.ai/docs';

  supportsLocation(_loc: Location): boolean {
    return true;
  }

  detect(loc: Location): DetectionResult {
    const mcpPath = mcpJsonPath(loc);
    const config = readJsonFile(mcpPath);
    const alreadyConfigured = !!config.mcpServers?.codegraph;
    // Detect ZCode by checking for the ~/.zcode config directory.
    const installed = loc === 'global'
      ? fs.existsSync(configDir('global'))
      : fs.existsSync(mcpPath) || fs.existsSync(path.join(process.cwd(), '.zcode'));
    return { installed, alreadyConfigured, configPath: mcpPath };
  }

  install(loc: Location, _opts: InstallOptions): WriteResult {
    const files: WriteResult['files'] = [];

    // 1. MCP server entry
    files.push(writeMcpEntry(loc));

    return {
      files,
      notes: ['Start a new ZCode session for MCP changes to take effect.'],
    };
  }

  uninstall(loc: Location): WriteResult {
    const files: WriteResult['files'] = [];

    // 1. MCP server entry
    const mcpPath = mcpJsonPath(loc);
    const config = readJsonFile(mcpPath);
    if (config.mcpServers?.codegraph) {
      delete config.mcpServers.codegraph;
      if (Object.keys(config.mcpServers).length === 0) {
        delete config.mcpServers;
      }
      writeJsonFile(mcpPath, config);
      files.push({ path: mcpPath, action: 'removed' });
    } else {
      files.push({ path: mcpPath, action: 'not-found' });
    }

    return { files };
  }

  printConfig(loc: Location): string {
    const target = mcpJsonPath(loc);
    const snippet = JSON.stringify(
      { mcpServers: { codegraph: getMcpServerConfig() } },
      null,
      2,
    );
    return `# Add to ${target}\n\n${snippet}\n`;
  }

  describePaths(loc: Location): string[] {
    return [mcpJsonPath(loc)];
  }
}

/**
 * Write the codegraph MCP entry to .mcp.json.
 *
 * Uses the same `mcpServers.codegraph` key as Claude Code. The entry is
 * idempotent — if the config already matches byte-for-byte, the file is
 * left untouched and reported `unchanged`.
 */
export function writeMcpEntry(loc: Location): WriteResult['files'][number] {
  const file = mcpJsonPath(loc);
  const existing = readJsonFile(file);
  const before = existing.mcpServers?.codegraph;
  const after = getMcpServerConfig();

  if (jsonDeepEqual(before, after)) {
    return { path: file, action: 'unchanged' };
  }

  const existed = fs.existsSync(file);
  const action: 'created' | 'updated' = before
    ? 'updated'
    : existed
      ? 'updated'
      : 'created';

  if (!existing.mcpServers) existing.mcpServers = {};
  existing.mcpServers.codegraph = after;
  writeJsonFile(file, existing);
  return { path: file, action };
}

export const zcodeTarget: AgentTarget = new ZCodeTarget();
