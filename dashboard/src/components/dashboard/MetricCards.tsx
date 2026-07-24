import React from 'react';
import { DollarSign, Users, Activity, Zap, TrendingUp, TrendingDown } from 'lucide-react';
import { cn } from '@/lib/utils';

interface MetricCardProps {
  title: string;
  value: string;
  trend: number;
  trendLabel: string;
  icon: React.ElementType;
  sparklineData: number[];
  color: 'blue' | 'emerald' | 'amber' | 'indigo';
}

const colorMap = {
  blue: { bg: 'bg-blue-100 dark:bg-blue-900/30', text: 'text-blue-600 dark:text-blue-400', fill: 'bg-blue-500 dark:bg-blue-400' },
  emerald: { bg: 'bg-emerald-100 dark:bg-emerald-900/30', text: 'text-emerald-600 dark:text-emerald-400', fill: 'bg-emerald-500 dark:bg-emerald-400' },
  amber: { bg: 'bg-amber-100 dark:bg-amber-900/30', text: 'text-amber-600 dark:text-amber-400', fill: 'bg-amber-500 dark:bg-amber-400' },
  indigo: { bg: 'bg-indigo-100 dark:bg-indigo-900/30', text: 'text-indigo-600 dark:text-indigo-400', fill: 'bg-indigo-500 dark:bg-indigo-400' },
};

function MetricCard({ title, value, trend, trendLabel, icon: Icon, sparklineData, color }: MetricCardProps) {
  const isPositive = trend >= 0;
  const colors = colorMap[color];

  return (
    <div className="bg-white dark:bg-slate-900 p-5 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm hover:shadow-md transition-shadow relative overflow-hidden group">
      <div className="flex justify-between items-start mb-4">
        <div>
          <p className="text-sm font-medium text-slate-500 dark:text-slate-400 mb-1">{title}</p>
          <h3 className="text-2xl font-bold text-slate-900 dark:text-white">{value}</h3>
        </div>
        <div className={cn("p-2.5 rounded-lg transition-colors", colors.bg, colors.text)}>
          <Icon className="w-5 h-5" />
        </div>
      </div>
      
      <div className="flex items-center justify-between mt-4">
        <div className="flex items-center gap-2" title={`${trend}% ${trendLabel}`}>
          <span className={cn(
            "flex items-center text-xs font-semibold px-2 py-1 rounded-md",
            isPositive 
              ? "text-emerald-700 bg-emerald-50 dark:text-emerald-400 dark:bg-emerald-400/10" 
              : "text-red-700 bg-red-50 dark:text-red-400 dark:bg-red-400/10"
          )}>
            {isPositive ? <TrendingUp className="w-3.5 h-3.5 mr-1" /> : <TrendingDown className="w-3.5 h-3.5 mr-1" />}
            {Math.abs(trend)}%
          </span>
          <span className="text-xs text-slate-500 dark:text-slate-400 hidden sm:inline-block">{trendLabel}</span>
        </div>
        
        {/* CSS Sparkline Representation */}
        <div className="flex items-end gap-1 h-8 opacity-70 group-hover:opacity-100 transition-opacity">
          {sparklineData.map((val, i) => (
            <div 
              key={i} 
              className={cn("w-1.5 rounded-t-sm transition-all duration-300 hover:opacity-80", colors.fill)}
              style={{ height: `${val}%` }}
              title={`Value: ${val}`}
            />
          ))}
        </div>
      </div>
    </div>
  );
}

export function MetricCards() {
  const metrics: MetricCardProps[] = [
    {
      title: "Total Revenue",
      value: "$124,563.00",
      trend: 12.4,
      trendLabel: "vs last month",
      icon: DollarSign,
      color: 'emerald',
      sparklineData: [40, 30, 60, 50, 80, 70, 100]
    },
    {
      title: "Active Subscribers",
      value: "8,234",
      trend: 5.2,
      trendLabel: "vs last month",
      icon: Users,
      color: 'blue',
      sparklineData: [50, 60, 55, 70, 80, 85, 90]
    },
    {
      title: "Credits Consumed",
      value: "2.4M",
      trend: -2.1,
      trendLabel: "vs last month",
      icon: Zap,
      color: 'amber',
      sparklineData: [90, 80, 85, 70, 60, 50, 40]
    },
    {
      title: "System Uptime",
      value: "99.99%",
      trend: 0.01,
      trendLabel: "vs last month",
      icon: Activity,
      color: 'indigo',
      sparklineData: [99, 100, 100, 99, 100, 100, 100]
    }
  ];

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 md:gap-6">
      {metrics.map((metric) => (
        <MetricCard key={metric.title} {...metric} />
      ))}
    </div>
  );
}
