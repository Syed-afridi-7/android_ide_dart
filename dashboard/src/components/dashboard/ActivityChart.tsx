import React, { useState } from 'react';
import { cn } from '@/lib/utils';

// Generate stable mock data for the chart
const generateMockData = (days: number) => {
  return Array.from({ length: days }, (_, i) => {
    // Creating some pseudo-random but realistic looking trends
    const baseCredits = 200 + Math.sin(i / 3) * 100;
    const noise = Math.random() * 50;
    return {
      day: i + 1,
      credits: Math.floor(baseCredits + noise),
      users: Math.floor((baseCredits + noise) * 0.4),
    };
  });
};

const fullData = generateMockData(90);

export function ActivityChart() {
  const [timeRange, setTimeRange] = useState<'7D' | '30D' | '90D'>('30D');

  const daysCount = timeRange === '7D' ? 7 : timeRange === '30D' ? 30 : 90;
  const chartData = fullData.slice(90 - daysCount);
  const maxCredits = Math.max(...chartData.map(d => d.credits), 100);

  return (
    <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-5 sm:p-6 shadow-sm">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8">
        <div>
          <h3 className="text-lg font-semibold text-slate-900 dark:text-white">Activity Overview</h3>
          <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">Daily credit consumption vs active users</p>
        </div>
        
        <div className="flex bg-slate-100 dark:bg-slate-800/50 rounded-lg p-1 self-start sm:self-auto border border-slate-200 dark:border-slate-700">
          {(['7D', '30D', '90D'] as const).map((range) => (
            <button
              key={range}
              onClick={() => setTimeRange(range)}
              className={cn(
                "text-xs py-1.5 px-3 rounded-md transition-all font-medium",
                timeRange === range
                  ? "bg-white dark:bg-slate-700 text-slate-900 dark:text-white shadow-sm"
                  : "text-slate-500 dark:text-slate-400 hover:text-slate-700 dark:hover:text-slate-200"
              )}
            >
              {range}
            </button>
          ))}
        </div>
      </div>

      <div className="relative h-72 w-full flex items-end pt-4">
        {/* Y-axis grid lines and labels */}
        <div className="absolute inset-0 flex flex-col justify-between pointer-events-none z-0">
          {[4, 3, 2, 1, 0].map((i) => (
            <div key={i} className="w-full border-t border-slate-100 dark:border-slate-800/50 flex items-center h-0">
              <span className="text-[10px] text-slate-400 -translate-y-2.5 bg-white dark:bg-slate-900 pr-3 font-medium w-12 text-right">
                {Math.round((maxCredits * i) / 4)}
              </span>
            </div>
          ))}
        </div>

        {/* Bars Container */}
        <div className="relative z-10 w-full h-full flex items-end justify-between gap-0.5 sm:gap-1 pl-12">
          {chartData.map((data, i) => {
            const creditHeight = (data.credits / maxCredits) * 100;
            const userHeight = (data.users / maxCredits) * 100;
            
            return (
              <div key={i} className="relative flex-1 group h-full flex flex-col justify-end">
                {/* Credit Bar */}
                <div 
                  className="w-full bg-indigo-200 dark:bg-indigo-900/40 rounded-t-sm group-hover:bg-indigo-300 dark:group-hover:bg-indigo-800/60 transition-colors relative"
                  style={{ height: `${creditHeight}%` }}
                >
                  {/* User Bar Overlay */}
                  <div 
                    className="absolute bottom-0 left-0 right-0 bg-indigo-600 dark:bg-indigo-500 rounded-t-sm opacity-90 group-hover:opacity-100 transition-opacity"
                    style={{ height: `${(userHeight / creditHeight) * 100}%` }}
                  />
                </div>
                
                {/* Custom Tooltip */}
                <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 bg-slate-900 text-white text-xs rounded-lg py-2 px-3 opacity-0 group-hover:opacity-100 pointer-events-none whitespace-nowrap z-50 transition-all shadow-xl translate-y-2 group-hover:translate-y-0">
                  <div className="font-semibold mb-1 border-b border-slate-700 pb-1">Day {data.day}</div>
                  <div className="flex items-center gap-2 text-indigo-200">
                    <div className="w-2 h-2 rounded-full bg-indigo-300" />
                    Credits: <span className="font-medium text-white">{data.credits}</span>
                  </div>
                  <div className="flex items-center gap-2 text-indigo-400 mt-1">
                    <div className="w-2 h-2 rounded-full bg-indigo-500" />
                    Users: <span className="font-medium text-white">{data.users}</span>
                  </div>
                  <div className="absolute -bottom-1 left-1/2 -translate-x-1/2 border-4 border-transparent border-t-slate-900"></div>
                </div>
              </div>
            );
          })}
        </div>
      </div>
      
      <div className="flex items-center justify-center gap-6 mt-6 pt-4 border-t border-slate-100 dark:border-slate-800">
        <div className="flex items-center gap-2">
          <div className="w-3 h-3 rounded bg-indigo-200 dark:bg-indigo-900/40 border border-indigo-300 dark:border-indigo-700" />
          <span className="text-xs font-medium text-slate-600 dark:text-slate-400">Total Credits</span>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-3 h-3 rounded bg-indigo-600 dark:bg-indigo-500" />
          <span className="text-xs font-medium text-slate-600 dark:text-slate-400">Active Users</span>
        </div>
      </div>
    </div>
  );
}
