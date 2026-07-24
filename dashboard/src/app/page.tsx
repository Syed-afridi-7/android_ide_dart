"use client";

import React, { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { AlertCircle } from 'lucide-react';
import Sidebar from '@/components/dashboard/Sidebar';
import Header from '@/components/dashboard/Header';
import MetricCards from '@/components/dashboard/MetricCards';
import ActivityChart from '@/components/dashboard/ActivityChart';
import CreditManager from '@/components/dashboard/CreditManager';
import DataTable from '@/components/dashboard/DataTable';
import { useAdminStore } from '@/store/useAdminStore';

export default function DashboardPage() {
  const [mounted, setMounted] = useState(false);
  const { config, subscribers } = useAdminStore();

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) return null;

  const totalAllocatedCredits = subscribers.reduce((acc, sub) => acc + sub.creditLimit, 0);
  const usedCredits = subscribers.reduce((acc, sub) => acc + sub.creditsUsed, 0);
  // Assume usageThresholdPercent is an integer like 80 or a fraction like 0.8. 
  // Let's use it as a percentage threshold where 80 = 80%.
  const thresholdFraction = (config.usageThresholdPercent > 1) ? config.usageThresholdPercent / 100 : config.usageThresholdPercent;
  const showWarning = 
    config.isExhaustionWarningEnabled && 
    totalAllocatedCredits > 0 &&
    (usedCredits / totalAllocatedCredits) >= thresholdFraction;

  const usagePercentage = totalAllocatedCredits > 0 ? (usedCredits / totalAllocatedCredits) * 100 : 0;

  return (
    <div className="flex h-screen overflow-hidden bg-slate-950 text-slate-50">
      <Sidebar />
      
      <div className="flex-1 flex flex-col min-w-0">
        <Header />
        
        <main className="flex-1 overflow-y-auto overflow-x-hidden p-6">
          <div className="max-w-7xl mx-auto space-y-6">
            <AnimatePresence>
              {showWarning && (
                <motion.div
                  initial={{ opacity: 0, y: -20, height: 0 }}
                  animate={{ opacity: 1, y: 0, height: 'auto' }}
                  exit={{ opacity: 0, y: -20, height: 0 }}
                  className="bg-rose-500/10 border border-rose-500/50 rounded-lg p-4 flex items-center gap-3 overflow-hidden"
                >
                  <AlertCircle className="w-5 h-5 text-rose-500 flex-shrink-0" />
                  <div className="flex-1">
                    <h3 className="text-sm font-medium text-rose-500">Credit Exhaustion Warning</h3>
                    <p className="text-sm text-rose-400/90 mt-1">
                      System-wide credit usage has exceeded {(thresholdFraction * 100).toFixed(0)}%. Current usage: {usagePercentage.toFixed(1)}%.
                    </p>
                  </div>
                </motion.div>
              )}
            </AnimatePresence>

            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.1 }}
            >
              <MetricCards />
            </motion.div>

            <motion.div 
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
              className="grid grid-cols-1 lg:grid-cols-3 gap-6"
            >
              <div className="lg:col-span-2">
                <ActivityChart />
              </div>
              <div className="lg:col-span-1">
                <CreditManager />
              </div>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.3 }}
            >
              <DataTable />
            </motion.div>
          </div>
        </main>
      </div>
    </div>
  );
}
