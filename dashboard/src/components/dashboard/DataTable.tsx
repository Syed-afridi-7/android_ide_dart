import React, { useState } from 'react';
import { Search, Filter, MoreHorizontal, ChevronLeft, ChevronRight, ArrowUpDown, Shield, Settings, AlertCircle, Ban } from 'lucide-react';
import { cn } from '@/lib/utils';

type Status = 'Active' | 'Warning' | 'Suspended' | 'Unlimited';

interface Subscriber {
  id: string;
  name: string;
  plan: string;
  credits: number;
  status: Status;
  lastActive: string;
}

const mockData: Subscriber[] = [
  { id: 'sub_001', name: 'Acme Corp', plan: 'Enterprise', credits: 450000, status: 'Active', lastActive: '2 mins ago' },
  { id: 'sub_002', name: 'Globex Inc', plan: 'Pro', credits: 12000, status: 'Warning', lastActive: '1 hr ago' },
  { id: 'sub_003', name: 'Initech', plan: 'Enterprise', credits: -1, status: 'Unlimited', lastActive: '5 mins ago' },
  { id: 'sub_004', name: 'Umbrella Corp', plan: 'Starter', credits: 0, status: 'Suspended', lastActive: '2 days ago' },
  { id: 'sub_005', name: 'Massive Dynamic', plan: 'Pro', credits: 85000, status: 'Active', lastActive: '10 mins ago' },
  { id: 'sub_006', name: 'Soylent Corp', plan: 'Enterprise', credits: 1200000, status: 'Active', lastActive: 'Just now' },
];

export function DataTable() {
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<Status | 'All'>('All');
  const [openDropdownId, setOpenDropdownId] = useState<string | null>(null);
  const [sortField, setSortField] = useState<'name' | 'credits'>('name');
  const [sortAsc, setSortAsc] = useState(true);

  // Close dropdown when clicking outside would typically go here

  const handleSort = (field: 'name' | 'credits') => {
    if (sortField === field) {
      setSortAsc(!sortAsc);
    } else {
      setSortField(field);
      setSortAsc(true);
    }
  };

  const filteredData = mockData
    .filter(item => 
      (item.name.toLowerCase().includes(searchTerm.toLowerCase()) || item.id.toLowerCase().includes(searchTerm.toLowerCase())) &&
      (statusFilter === 'All' || item.status === statusFilter)
    )
    .sort((a, b) => {
      let comparison = 0;
      if (sortField === 'name') {
        comparison = a.name.localeCompare(b.name);
      } else if (sortField === 'credits') {
        comparison = a.credits - b.credits;
      }
      return sortAsc ? comparison : -comparison;
    });

  const StatusBadge = ({ status }: { status: Status }) => {
    const styles = {
      Active: 'bg-emerald-50 text-emerald-700 dark:bg-emerald-400/10 dark:text-emerald-400 border-emerald-200 dark:border-emerald-800/30',
      Warning: 'bg-amber-50 text-amber-700 dark:bg-amber-400/10 dark:text-amber-400 border-amber-200 dark:border-amber-800/30',
      Suspended: 'bg-red-50 text-red-700 dark:bg-red-400/10 dark:text-red-400 border-red-200 dark:border-red-800/30',
      Unlimited: 'bg-indigo-50 text-indigo-700 dark:bg-indigo-400/10 dark:text-indigo-400 border-indigo-200 dark:border-indigo-800/30',
    };

    return (
      <span className={cn("inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold border", styles[status])}>
        {status}
      </span>
    );
  };

  return (
    <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm overflow-hidden flex flex-col">
      <div className="p-5 border-b border-slate-200 dark:border-slate-800 flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-slate-50/50 dark:bg-slate-900/50">
        <div className="relative max-w-md w-full">
          <div className="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
            <Search className="w-4 h-4 text-slate-400" />
          </div>
          <input
            type="text"
            placeholder="Search accounts or IDs..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="block w-full pl-9 pr-3 py-2 text-sm bg-white dark:bg-slate-800 border border-slate-300 dark:border-slate-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 transition-colors shadow-sm"
          />
        </div>
        
        <div className="flex items-center gap-2">
          <div className="relative">
            <Filter className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400 pointer-events-none" />
            <select 
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value as Status | 'All')}
              className="text-sm bg-white dark:bg-slate-800 border border-slate-300 dark:border-slate-700 rounded-lg py-2 pl-9 pr-8 focus:outline-none focus:ring-2 focus:ring-indigo-500 shadow-sm appearance-none cursor-pointer"
            >
              <option value="All">All Statuses</option>
              <option value="Active">Active</option>
              <option value="Warning">Warning</option>
              <option value="Suspended">Suspended</option>
              <option value="Unlimited">Unlimited</option>
            </select>
          </div>
        </div>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full text-sm text-left">
          <thead className="text-xs text-slate-500 uppercase bg-slate-50 dark:bg-slate-800/50 dark:text-slate-400 border-b border-slate-200 dark:border-slate-800">
            <tr>
              <th 
                className="px-6 py-4 font-semibold cursor-pointer hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors group"
                onClick={() => handleSort('name')}
              >
                <div className="flex items-center gap-1.5">
                  Account Name
                  <ArrowUpDown className={cn("w-3.5 h-3.5", sortField === 'name' ? "text-indigo-500" : "opacity-0 group-hover:opacity-100 transition-opacity")} />
                </div>
              </th>
              <th className="px-6 py-4 font-semibold">Plan</th>
              <th 
                className="px-6 py-4 font-semibold cursor-pointer hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors group"
                onClick={() => handleSort('credits')}
              >
                <div className="flex items-center gap-1.5">
                  Credits Balance
                  <ArrowUpDown className={cn("w-3.5 h-3.5", sortField === 'credits' ? "text-indigo-500" : "opacity-0 group-hover:opacity-100 transition-opacity")} />
                </div>
              </th>
              <th className="px-6 py-4 font-semibold">Status</th>
              <th className="px-6 py-4 font-semibold">Last Active</th>
              <th className="px-6 py-4 font-semibold text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {filteredData.length > 0 ? (
              filteredData.map((row) => (
                <tr key={row.id} className="border-b border-slate-100 dark:border-slate-800/50 hover:bg-slate-50 dark:hover:bg-slate-800/30 transition-colors">
                  <td className="px-6 py-4">
                    <div className="font-bold text-slate-900 dark:text-white">{row.name}</div>
                    <div className="text-xs text-slate-500 mt-0.5 font-mono">{row.id}</div>
                  </td>
                  <td className="px-6 py-4 font-medium text-slate-700 dark:text-slate-300">{row.plan}</td>
                  <td className="px-6 py-4">
                    <span className="font-mono font-medium text-slate-800 dark:text-slate-200">
                      {row.credits === -1 ? 'Unlimited (∞)' : row.credits.toLocaleString()}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <StatusBadge status={row.status} />
                  </td>
                  <td className="px-6 py-4 text-slate-500 dark:text-slate-400">{row.lastActive}</td>
                  <td className="px-6 py-4 text-right relative">
                    <button 
                      onClick={() => setOpenDropdownId(openDropdownId === row.id ? null : row.id)}
                      className="p-2 text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition-colors focus:outline-none focus:ring-2 focus:ring-indigo-500"
                    >
                      <MoreHorizontal className="w-4 h-4" />
                    </button>
                    
                    {openDropdownId === row.id && (
                      <div className="absolute right-8 top-12 w-48 bg-white dark:bg-slate-800 rounded-xl shadow-xl border border-slate-200 dark:border-slate-700 py-1.5 z-20 animate-in fade-in zoom-in-95 duration-100">
                        <button className="w-full flex items-center gap-2.5 px-4 py-2 text-sm text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700/50 transition-colors">
                          <Settings className="w-4 h-4 text-slate-400" /> Adjust Credits
                        </button>
                        <button className="w-full flex items-center gap-2.5 px-4 py-2 text-sm text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700/50 transition-colors">
                          <Shield className="w-4 h-4 text-slate-400" /> View Audit
                        </button>
                        <button className="w-full flex items-center gap-2.5 px-4 py-2 text-sm text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700/50 transition-colors">
                          <AlertCircle className="w-4 h-4 text-slate-400" /> Change Plan
                        </button>
                        <div className="h-px bg-slate-200 dark:bg-slate-700 my-1.5 mx-2" />
                        <button className="w-full flex items-center gap-2.5 px-4 py-2 text-sm text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-500/10 transition-colors">
                          <Ban className="w-4 h-4" /> Suspend Account
                        </button>
                      </div>
                    )}
                  </td>
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan={6} className="px-6 py-12 text-center text-slate-500 dark:text-slate-400">
                  No subscribers found matching your criteria.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      <div className="p-4 border-t border-slate-200 dark:border-slate-800 flex items-center justify-between bg-slate-50/50 dark:bg-slate-900/50">
        <span className="text-sm font-medium text-slate-500 dark:text-slate-400">
          Showing <span className="text-slate-900 dark:text-white">1</span> to <span className="text-slate-900 dark:text-white">{filteredData.length}</span> of <span className="text-slate-900 dark:text-white">{filteredData.length}</span> results
        </span>
        <div className="flex items-center gap-1.5">
          <button className="p-1.5 text-slate-400 hover:text-slate-600 dark:hover:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-800 rounded-md disabled:opacity-50 transition-colors">
            <ChevronLeft className="w-4 h-4" />
          </button>
          <button className="w-8 h-8 flex items-center justify-center rounded-lg bg-indigo-600 text-white font-medium text-sm shadow-sm">
            1
          </button>
          <button className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-slate-200 dark:hover:bg-slate-800 text-slate-600 dark:text-slate-300 text-sm font-medium transition-colors">
            2
          </button>
          <button className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-slate-200 dark:hover:bg-slate-800 text-slate-600 dark:text-slate-300 text-sm font-medium transition-colors">
            ...
          </button>
          <button className="p-1.5 text-slate-400 hover:text-slate-600 dark:hover:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-800 rounded-md disabled:opacity-50 transition-colors">
            <ChevronRight className="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  );
}
