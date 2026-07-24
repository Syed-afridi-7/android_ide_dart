import React, { useState } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { 
  LayoutDashboard, 
  BarChart3, 
  Users, 
  CreditCard, 
  ShieldCheck, 
  Settings, 
  ChevronLeft, 
  ChevronRight, 
  Sparkles,
  MoreVertical
} from 'lucide-react';
import { cn } from '@/lib/utils';
// import { useAdminStore } from '@/store/useAdminStore';

// Temporary mock for useAdminStore if not created yet
const useAdminStore = () => ({
  environment: 'Production',
  setEnvironment: (env: string) => {},
});

const navItems = [
  { name: 'Overview', href: '/dashboard', icon: LayoutDashboard },
  { name: 'Analytics', href: '/dashboard/analytics', icon: BarChart3 },
  { name: 'Subscriptions', href: '/dashboard/subscriptions', icon: Users },
  { name: 'Credit Control', href: '/dashboard/credits', icon: CreditCard },
  { name: 'Audit Logs', href: '/dashboard/audit', icon: ShieldCheck },
  { name: 'Settings', href: '/dashboard/settings', icon: Settings },
];

export function Sidebar() {
  const [isCollapsed, setIsCollapsed] = useState(false);
  const pathname = usePathname();
  // In real implementation: const { environment, setEnvironment } = useAdminStore();
  const { environment, setEnvironment } = useAdminStore();

  return (
    <aside
      className={cn(
        "relative flex flex-col h-screen bg-slate-50 dark:bg-slate-900 border-r border-slate-200 dark:border-slate-800 transition-all duration-300",
        isCollapsed ? "w-20" : "w-64"
      )}
    >
      <div className="flex items-center justify-between p-4 border-b border-slate-200 dark:border-slate-800 h-16">
        {!isCollapsed && (
          <div className="flex items-center gap-2 overflow-hidden">
            <Sparkles className="w-6 h-6 flex-shrink-0 text-indigo-600 dark:text-indigo-400" />
            <span className="font-bold text-lg text-slate-900 dark:text-white truncate">AdminUI</span>
            <span className="px-2 py-0.5 text-[10px] uppercase font-bold rounded-full bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400">
              {environment}
            </span>
          </div>
        )}
        {isCollapsed && <Sparkles className="w-6 h-6 text-indigo-600 dark:text-indigo-400 mx-auto" />}
        <button
          onClick={() => setIsCollapsed(!isCollapsed)}
          className="absolute -right-3 top-5 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-full p-1 hover:bg-slate-100 dark:hover:bg-slate-700 transition-colors z-50 shadow-sm"
          aria-label={isCollapsed ? "Expand sidebar" : "Collapse sidebar"}
        >
          {isCollapsed ? <ChevronRight className="w-4 h-4" /> : <ChevronLeft className="w-4 h-4" />}
        </button>
      </div>

      <nav className="flex-1 overflow-y-auto p-3 space-y-1">
        {navItems.map((item) => {
          const isActive = pathname === item.href || (pathname?.startsWith(item.href) && item.href !== '/dashboard');
          const Icon = item.icon;
          return (
            <Link
              key={item.name}
              href={item.href}
              className={cn(
                "flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all group relative",
                isActive 
                  ? "bg-indigo-50 text-indigo-700 dark:bg-indigo-500/10 dark:text-indigo-400 font-medium" 
                  : "text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800/50 hover:text-slate-900 dark:hover:text-slate-200"
              )}
            >
              <Icon className={cn("w-5 h-5 flex-shrink-0", isActive ? "text-indigo-600 dark:text-indigo-400" : "text-slate-500 dark:text-slate-400 group-hover:text-slate-700 dark:group-hover:text-slate-300")} />
              {!isCollapsed && <span>{item.name}</span>}
              {isCollapsed && (
                <div className="absolute left-full ml-2 px-2 py-1 bg-slate-800 text-xs font-medium text-white rounded opacity-0 pointer-events-none group-hover:opacity-100 transition-opacity z-50 whitespace-nowrap shadow-md">
                  {item.name}
                </div>
              )}
            </Link>
          );
        })}
      </nav>

      <div className="p-4 border-t border-slate-200 dark:border-slate-800">
        {!isCollapsed ? (
          <div className="flex flex-col gap-2">
            <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">Context</span>
            <div className="flex bg-slate-200/50 dark:bg-slate-800 rounded-lg p-1">
              {['Production', 'Staging', 'Sandbox'].map((env) => (
                <button
                  key={env}
                  onClick={() => setEnvironment(env)}
                  className={cn(
                    "flex-1 text-xs py-1.5 px-1 rounded-md transition-all duration-200",
                    environment === env 
                      ? "bg-white dark:bg-slate-700 text-slate-900 dark:text-white shadow-sm font-medium" 
                      : "text-slate-500 dark:text-slate-400 hover:text-slate-700 dark:hover:text-slate-200 hover:bg-slate-200/50 dark:hover:bg-slate-700/50"
                  )}
                  title={env}
                >
                  {env.slice(0, 4)}
                </button>
              ))}
            </div>
          </div>
        ) : (
          <button className="w-full flex justify-center text-slate-500 hover:text-slate-700 dark:hover:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 p-2 rounded-lg transition-colors">
            <MoreVertical className="w-5 h-5" />
          </button>
        )}
      </div>
    </aside>
  );
}
