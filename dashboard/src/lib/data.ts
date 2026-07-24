export interface Metric {
  title: string;
  value: string;
  change: number;
  trend: "up" | "down" | "neutral";
}

export const mockMetricsData = {
  totalRevenue: { title: "Total Revenue", value: "$124,563", change: 12.5, trend: "up" },
  activeSubscribers: { title: "Active Subscribers", value: "2,845", change: 4.2, trend: "up" },
  creditConsumption: { title: "Credit Consumption", value: "8.4M", change: -2.1, trend: "down" },
  apiRequests: { title: "API Requests", value: "142.3M", change: 8.4, trend: "up" },
  conversionRate: { title: "Conversion Rate", value: "4.8%", change: 0.2, trend: "up" }
};

export interface AuditLog {
  id: string;
  timestamp: string;
  actor: string;
  action: string;
  details: string;
  status: "success" | "warning" | "failure";
}

export const mockAuditLogs: AuditLog[] = [
  { id: "log_1", timestamp: "2026-07-24T10:00:00Z", actor: "admin@example.com", action: "UPDATE_PLAN", details: "Upgraded sub_123 to Enterprise", status: "success" },
  { id: "log_2", timestamp: "2026-07-24T10:15:00Z", actor: "system", action: "AUTO_RECHARGE", details: "Added 1000 credits to sub_456", status: "success" },
  { id: "log_3", timestamp: "2026-07-24T11:05:00Z", actor: "jdoe@example.com", action: "DELETE_USER", details: "Deleted user sub_789", status: "warning" },
  { id: "log_4", timestamp: "2026-07-24T11:30:00Z", actor: "admin@example.com", action: "CREDIT_ADJUSTMENT", details: "Deducted 500 credits from sub_111 due to abuse", status: "success" }
];

export interface Subscriber {
  id: string;
  name: string;
  email: string;
  plan: "Free" | "Pro" | "Enterprise";
  creditsRemaining: number;
  status: "active" | "inactive" | "suspended";
  lastActive: string;
}

export const mockSubscribers: Subscriber[] = [
  { id: "sub_1", name: "Acme Corp", email: "admin@acme.com", plan: "Enterprise", creditsRemaining: 450000, status: "active", lastActive: "2026-07-24T12:00:00Z" },
  { id: "sub_2", name: "TechStart", email: "hello@techstart.io", plan: "Pro", creditsRemaining: 2500, status: "active", lastActive: "2026-07-23T15:30:00Z" },
  { id: "sub_3", name: "John Doe", email: "jdoe@gmail.com", plan: "Free", creditsRemaining: 0, status: "inactive", lastActive: "2026-07-01T08:00:00Z" },
  { id: "sub_4", name: "Global Systems", email: "it@globalsys.net", plan: "Enterprise", creditsRemaining: 1200000, status: "active", lastActive: "2026-07-24T10:45:00Z" }
];
