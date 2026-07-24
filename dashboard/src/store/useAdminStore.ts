import { create } from "zustand";
import { mockSubscribers, mockAuditLogs, type Subscriber, type AuditLog } from "../lib/data";

interface AdminState {
  totalAllocatedCredits: number;
  usedCredits: number;
  usageThresholdPercent: number;
  isExhaustionWarningEnabled: boolean;
  autoRechargeEnabled: boolean;
  selectedContext: "production" | "staging" | "sandbox";
  sidebarCollapsed: boolean;
  searchQuery: string;
  subscribers: Subscriber[];
  auditLogs: AuditLog[];
  
  adjustCredits: (subscriberId: string, delta: number) => void;
  setThreshold: (percent: number) => void;
  toggleExhaustionWarning: () => void;
  toggleAutoRecharge: () => void;
  setContext: (ctx: "production" | "staging" | "sandbox") => void;
  toggleSidebar: () => void;
  setSearchQuery: (q: string) => void;
  addAuditLog: (action: string, details: string, actor?: string) => void;
}

export const useAdminStore = create<AdminState>((set) => ({
  totalAllocatedCredits: 10000000,
  usedCredits: 8400000,
  usageThresholdPercent: 85,
  isExhaustionWarningEnabled: true,
  autoRechargeEnabled: false,
  selectedContext: "production",
  sidebarCollapsed: false,
  searchQuery: "",
  subscribers: mockSubscribers,
  auditLogs: mockAuditLogs,
  
  adjustCredits: (subscriberId, delta) => set((state) => ({
    subscribers: state.subscribers.map(sub => 
      sub.id === subscriberId ? { ...sub, creditsRemaining: Math.max(0, sub.creditsRemaining + delta) } : sub
    )
  })),
  
  setThreshold: (percent) => set({ usageThresholdPercent: percent }),
  
  toggleExhaustionWarning: () => set((state) => ({ isExhaustionWarningEnabled: !state.isExhaustionWarningEnabled })),
  
  toggleAutoRecharge: () => set((state) => ({ autoRechargeEnabled: !state.autoRechargeEnabled })),
  
  setContext: (ctx) => set({ selectedContext: ctx }),
  
  toggleSidebar: () => set((state) => ({ sidebarCollapsed: !state.sidebarCollapsed })),
  
  setSearchQuery: (q) => set({ searchQuery: q }),
  
  addAuditLog: (action, details, actor = "admin") => set((state) => {
    const newLog: AuditLog = {
      id: `log_${Date.now()}`,
      timestamp: new Date().toISOString(),
      actor,
      action,
      details,
      status: "success"
    };
    return { auditLogs: [newLog, ...state.auditLogs] };
  })
}));
