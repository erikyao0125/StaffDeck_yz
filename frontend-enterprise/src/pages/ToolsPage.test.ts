import { describe, expect, it } from 'vitest';

import { buildBucketStats, parseMcpArgs } from './ToolsPage';
import { ToolStatusFilter } from '@/enums/toolStatus';
import type { ToolRead } from '../types';

describe('parseMcpArgs', () => {
  it('preserves spaces inside one argument', () => {
    expect(parseMcpArgs('C:\\Program Files\\mcp server\\index.js')).toEqual([
      'C:\\Program Files\\mcp server\\index.js',
    ]);
  });

  it('uses one non-empty line per argument', () => {
    expect(parseMcpArgs('-m\nmy_mcp.server\n\n--label=customer support')).toEqual([
      '-m',
      'my_mcp.server',
      '--label=customer support',
    ]);
  });
});

describe('buildBucketStats and disabled tool retention', () => {
  const sampleTools: ToolRead[] = [
    {
      id: 'tool-1',
      tenant_id: 'tenant-1',
      name: 'tool_active',
      display_name: '活跃工具',
      bucket: '业务工具',
      tool_type: 'http',
      method: 'POST',
      url: 'https://api.example.com/1',
      headers: {},
      auth: {},
      mcp_config: {},
      input_schema: {},
      output_schema: {},
      allowed_skills: [],
      capability_scope: 'general',
      enabled: true,
      created_at: '2026-09-01T00:00:00Z',
      updated_at: '2026-09-01T00:00:00Z',
    },
    {
      id: 'tool-2',
      tenant_id: 'tenant-1',
      name: 'tool_disabled',
      display_name: '已禁用工具',
      bucket: '业务工具',
      tool_type: 'http',
      method: 'POST',
      url: 'https://api.example.com/2',
      headers: {},
      auth: {},
      mcp_config: {},
      input_schema: {},
      output_schema: {},
      allowed_skills: [],
      capability_scope: 'general',
      enabled: false,
      created_at: '2026-09-01T00:00:00Z',
      updated_at: '2026-09-01T00:00:00Z',
    },
  ];

  it('buildBucketStats counts both enabled and disabled tools', () => {
    const stats = buildBucketStats(sampleTools);
    expect(stats).toEqual([
      {
        bucket: '业务工具',
        total: 2,
        enabled: 1,
        disabled: 1,
      },
    ]);
  });

  it('filters tools correctly according to ToolStatusFilter enum', () => {
    const filterByStatus = (tools: ToolRead[], filter: ToolStatusFilter) =>
      tools.filter((row) => {
        if (filter === ToolStatusFilter.All) return true;
        return filter === ToolStatusFilter.Enabled ? row.enabled : !row.enabled;
      });

    expect(filterByStatus(sampleTools, ToolStatusFilter.All)).toHaveLength(2);
    expect(filterByStatus(sampleTools, ToolStatusFilter.Enabled)).toHaveLength(1);
    expect(filterByStatus(sampleTools, ToolStatusFilter.Disabled)).toHaveLength(1);
    expect(filterByStatus(sampleTools, ToolStatusFilter.Disabled)[0].id).toBe('tool-2');
  });
});
