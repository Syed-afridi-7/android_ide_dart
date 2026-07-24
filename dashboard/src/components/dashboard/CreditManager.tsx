import React, { useState } from 'react';
import { Settings2, AlertTriangle, Plus, ArrowRightLeft, CheckCircle2, X } from 'lucide-react';
import { cn } from '@/lib/utils';

export function CreditManager() {
  const [threshold, setThreshold] = useState(85);
  const [warningEnabled, setWarningEnabled] = useState(true);
  const [autoRecharge, setAutoRecharge] = useState(false);
  const [isModalOpen, setIsModalOpen] = useState(false);

  const totalCredits = 1000000;
  const usedCredits = 824500;
  const usagePercentage = (usedCredits / totalCredits) * 100;

  return (
    <div className="space-y-6">
      <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-5 sm:p-6 shadow-sm">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
          <div>
            <h2 className="text-lg font-semibold text-slate-900 dark:text-white flex items-center gap-2">
              <Settings2 className="w-5 h-5 text-indigo-500" />
              Credit & Subscription Control
            </h2>
            <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">Manage global allocation, thresholds, and automated actions.</p>
          </div>
          <button 
            onClick={() => setIsModalOpen(true)}
            className="flex items-center gap-2 px-4 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-medium rounded-lg transition-colors shadow-sm focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 dark:focus:ring-offset-slate-900"
          >
            <Plus className="w-4 h-4" />
            Allocate Credits
          </button>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 lg:gap-12">
          <div className="space-y-5">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm font-medium text-slate-700 dark:text-slate-300">Global Pool Usage</span>
              <div className="flex items-center gap-3">
                {usagePercentage >= threshold && (
                  <span className="flex items-center gap-1.5 text-xs font-semibold text-amber-700 bg-amber-50 dark:text-amber-400 dark:bg-amber-400/10 px-2.5 py-1 rounded-full border border-amber-200 dark:border-amber-800/50">
                    <AlertTriangle className="w-3.5 h-3.5" />
                    High Usage Alert
                  </span>
                )}
                <span className="text-lg font-bold text-slate-900 dark:text-white">{usagePercentage.toFixed(1)}%</span>
              </div>
            </div>
            
            <div className="relative w-full h-4 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden shadow-inner">
              <div 
                className={cn(
                  "h-full rounded-full transition-all duration-1000 ease-out",
                  usagePercentage >= 90 ? "bg-red-500" : usagePercentage >= threshold ? "bg-amber-500" : "bg-emerald-500"
                )}
                style={{ width: `${usagePercentage}%` }}
              />
              <div 
                className="absolute top-0 bottom-0 w-1 bg-slate-900/50 dark:bg-white/50 z-10 cursor-pointer hover:bg-slate-900 dark:hover:bg-white transition-colors"
                style={{ left: `${threshold}%` }}
                title={`Threshold: ${threshold}%`}
              />
            </div>
            <div className="flex justify-between text-sm text-slate-500 dark:text-slate-400 font-medium">
              <span>{usedCredits.toLocaleString()} used</span>
              <span>{totalCredits.toLocaleString()} allocated</span>
            </div>
          </div>

          <div className="space-y-6 bg-slate-50 dark:bg-slate-800/30 p-5 rounded-xl border border-slate-100 dark:border-slate-800">
            <div className="flex items-center justify-between gap-4">
              <div className="flex-1">
                <label className="text-sm font-semibold text-slate-900 dark:text-white flex justify-between">
                  Alert Threshold
                  <span className="text-indigo-600 dark:text-indigo-400">{threshold}%</span>
                </label>
                <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">Trigger system warning when usage exceeds this limit.</p>
              </div>
              <input 
                type="range" 
                min="50" 
                max="95" 
                step="5"
                value={threshold} 
                onChange={(e) => setThreshold(Number(e.target.value))}
                className="w-32 accent-indigo-600 cursor-pointer"
              />
            </div>
            
            <div className="flex items-center justify-between gap-4 pt-4 border-t border-slate-200 dark:border-slate-700/50">
              <div className="flex-1">
                <span className="text-sm font-semibold text-slate-900 dark:text-white">Plan Exhaustion Warning Banner</span>
                <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">Show persistent banner to enterprise subscribers on low balance.</p>
              </div>
              <button 
                onClick={() => setWarningEnabled(!warningEnabled)}
                className={cn(
                  "relative inline-flex h-6 w-11 items-center rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 dark:focus:ring-offset-slate-800", 
                  warningEnabled ? "bg-indigo-600" : "bg-slate-300 dark:bg-slate-600"
                )}
              >
                <span className={cn(
                  "inline-block h-4 w-4 transform rounded-full bg-white transition-transform shadow-sm", 
                  warningEnabled ? "translate-x-6" : "translate-x-1"
                )} />
              </button>
            </div>

            <div className="flex items-center justify-between gap-4 pt-4 border-t border-slate-200 dark:border-slate-700/50">
              <div className="flex-1">
                <span className="text-sm font-semibold text-slate-900 dark:text-white">Auto-Recharge Engine</span>
                <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">Automatically bill and top up enterprise plans when depleted.</p>
              </div>
              <button 
                onClick={() => setAutoRecharge(!autoRecharge)}
                className={cn(
                  "relative inline-flex h-6 w-11 items-center rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 dark:focus:ring-offset-slate-800", 
                  autoRecharge ? "bg-indigo-600" : "bg-slate-300 dark:bg-slate-600"
                )}
              >
                <span className={cn(
                  "inline-block h-4 w-4 transform rounded-full bg-white transition-transform shadow-sm", 
                  autoRecharge ? "translate-x-6" : "translate-x-1"
                )} />
              </button>
            </div>
          </div>
        </div>
      </div>

      <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-0 shadow-sm overflow-hidden">
        <div className="p-5 border-b border-slate-200 dark:border-slate-800">
          <h3 className="text-base font-semibold text-slate-900 dark:text-white">Recent Admin Adjustments</h3>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm text-left whitespace-nowrap">
            <thead className="text-xs text-slate-500 uppercase bg-slate-50 dark:bg-slate-800/50 dark:text-slate-400">
              <tr>
                <th className="px-6 py-4 font-semibold">Account</th>
                <th className="px-6 py-4 font-semibold">Type</th>
                <th className="px-6 py-4 font-semibold">Amount</th>
                <th className="px-6 py-4 font-semibold">Status</th>
                <th className="px-6 py-4 font-semibold text-right">Date</th>
              </tr>
            </thead>
            <tbody>
              {[
                { account: 'Acme Corp', type: 'Addition', amount: '+50,000', status: 'Completed', date: '2 mins ago' },
                { account: 'Globex Inc', type: 'Deduction', amount: '-10,000', status: 'Pending', date: '1 hr ago' },
                { account: 'Initech', type: 'Addition', amount: '+100,000', status: 'Completed', date: '3 hrs ago' },
              ].map((log, i) => (
                <tr key={i} className="border-b border-slate-100 dark:border-slate-800 last:border-0 hover:bg-slate-50/50 dark:hover:bg-slate-800/30 transition-colors">
                  <td className="px-6 py-4 font-medium text-slate-900 dark:text-white">{log.account}</td>
                  <td className="px-6 py-4">
                    <span className="flex items-center gap-2 text-slate-600 dark:text-slate-300">
                      <ArrowRightLeft className="w-4 h-4 text-slate-400" />
                      {log.type}
                    </span>
                  </td>
                  <td className={cn("px-6 py-4 font-bold", log.amount.startsWith('+') ? "text-emerald-600 dark:text-emerald-400" : "text-red-600 dark:text-red-400")}>
                    {log.amount}
                  </td>
                  <td className="px-6 py-4">
                    {log.status === 'Completed' ? (
                      <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-700 dark:bg-emerald-400/10 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-800/30">
                        <CheckCircle2 className="w-3.5 h-3.5" /> Completed
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-amber-50 text-amber-700 dark:bg-amber-400/10 dark:text-amber-400 border border-amber-200 dark:border-amber-800/30">
                        Pending
                      </span>
                    )}
                  </td>
                  <td className="px-6 py-4 text-slate-500 dark:text-slate-400 text-right">{log.date}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
      
      {/* Quick Allocation Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-white dark:bg-slate-900 p-6 rounded-2xl w-full max-w-md shadow-2xl border border-slate-200 dark:border-slate-800">
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-xl font-bold text-slate-900 dark:text-white">Allocate Credits</h3>
              <button onClick={() => setIsModalOpen(false)} className="p-1 rounded-full hover:bg-slate-100 dark:hover:bg-slate-800 text-slate-500 transition-colors">
                <X className="w-5 h-5" />
              </button>
            </div>
            
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-semibold text-slate-700 dark:text-slate-300 mb-1.5">Subscriber ID / Email</label>
                <input 
                  type="text" 
                  className="w-full px-4 py-2.5 border border-slate-300 dark:border-slate-700 rounded-lg bg-transparent focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-all dark:text-white" 
                  placeholder="sub_123456 or name@company.com" 
                />
              </div>
              
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-semibold text-slate-700 dark:text-slate-300 mb-1.5">Action</label>
                  <select className="w-full px-4 py-2.5 border border-slate-300 dark:border-slate-700 rounded-lg bg-transparent focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-all dark:text-white">
                    <option value="add">Add Credits</option>
                    <option value="deduct">Deduct Credits</option>
                    <option value="set">Set Balance</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-semibold text-slate-700 dark:text-slate-300 mb-1.5">Amount</label>
                  <input 
                    type="number" 
                    className="w-full px-4 py-2.5 border border-slate-300 dark:border-slate-700 rounded-lg bg-transparent focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-all dark:text-white" 
                    placeholder="10,000" 
                  />
                </div>
              </div>
              
              <div>
                <label className="block text-sm font-semibold text-slate-700 dark:text-slate-300 mb-1.5">Reason (Optional)</label>
                <input 
                  type="text" 
                  className="w-full px-4 py-2.5 border border-slate-300 dark:border-slate-700 rounded-lg bg-transparent focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-all dark:text-white" 
                  placeholder="e.g. Enterprise upgrade bonus" 
                />
              </div>
            </div>
            
            <div className="mt-8 flex justify-end gap-3">
              <button 
                onClick={() => setIsModalOpen(false)} 
                className="px-5 py-2.5 text-sm font-medium text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition-colors"
              >
                Cancel
              </button>
              <button 
                onClick={() => setIsModalOpen(false)} 
                className="px-5 py-2.5 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg transition-colors shadow-sm"
              >
                Confirm Allocation
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
