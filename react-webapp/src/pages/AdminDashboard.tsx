import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  LayoutDashboard, ShoppingBag, Users, Package, Settings, LogOut,
  TrendingUp, TrendingDown, DollarSign, Eye, ShoppingCart, Star,
  Bell, Search, ChevronRight, MoreVertical, ArrowUpRight,
  BarChart3, PieChart, Calendar, Filter, Menu, X
} from 'lucide-react';
import { useNavigate } from 'react-router-dom';

// Mock data
const STATS = [
  { label: 'Total Revenue', value: '₹12,45,890', change: '+18.2%', trend: 'up', icon: DollarSign, color: '#6366f1' },
  { label: 'Total Orders', value: '3,256', change: '+12.5%', trend: 'up', icon: ShoppingCart, color: '#22d3ee' },
  { label: 'Active Users', value: '8,432', change: '+8.7%', trend: 'up', icon: Users, color: '#a855f7' },
  { label: 'Conversion Rate', value: '3.24%', change: '-0.4%', trend: 'down', icon: TrendingUp, color: '#f59e0b' },
];

const RECENT_ORDERS = [
  { id: '#JD-2045', customer: 'Rahul Sharma', product: 'Premium Black Hoodie', amount: '₹2,999', status: 'Delivered', date: '5 Jun, 2026', avatar: 'RS' },
  { id: '#JD-2044', customer: 'Priya Patel', product: 'Oversized Tee - White', amount: '₹1,499', status: 'Shipped', date: '5 Jun, 2026', avatar: 'PP' },
  { id: '#JD-2043', customer: 'Arjun Kumar', product: 'Cargo Joggers', amount: '₹3,499', status: 'Processing', date: '4 Jun, 2026', avatar: 'AK' },
  { id: '#JD-2042', customer: 'Sneha Reddy', product: 'Graphic Hoodie - Navy', amount: '₹2,799', status: 'Delivered', date: '4 Jun, 2026', avatar: 'SR' },
  { id: '#JD-2041', customer: 'Vikram Singh', product: 'Classic Polo - Olive', amount: '₹1,899', status: 'Cancelled', date: '3 Jun, 2026', avatar: 'VS' },
  { id: '#JD-2040', customer: 'Ananya Gupta', product: 'Summer Dress - Floral', amount: '₹2,299', status: 'Shipped', date: '3 Jun, 2026', avatar: 'AG' },
];

const TOP_PRODUCTS = [
  { name: 'Premium Black Hoodie', sales: 856, revenue: '₹25.6L', image: 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?auto=format&fit=crop&q=80&w=100', rating: 4.8 },
  { name: 'Oversized Tee - White', sales: 723, revenue: '₹10.8L', image: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&q=80&w=100', rating: 4.6 },
  { name: 'Cargo Joggers - Khaki', sales: 645, revenue: '₹22.5L', image: 'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?auto=format&fit=crop&q=80&w=100', rating: 4.5 },
  { name: 'Graphic Hoodie - Navy', sales: 512, revenue: '₹14.3L', image: 'https://images.unsplash.com/photo-1522512115668-c09775d6f424?auto=format&fit=crop&q=80&w=100', rating: 4.7 },
];

const SIDEBAR_ITEMS = [
  { icon: LayoutDashboard, label: 'Dashboard', active: true },
  { icon: ShoppingBag, label: 'Orders', active: false },
  { icon: Package, label: 'Products', active: false },
  { icon: Users, label: 'Customers', active: false },
  { icon: BarChart3, label: 'Analytics', active: false },
  { icon: Settings, label: 'Settings', active: false },
];

// Revenue chart bars (last 7 days mock)
const CHART_DATA = [
  { day: 'Mon', value: 65 },
  { day: 'Tue', value: 45 },
  { day: 'Wed', value: 80 },
  { day: 'Thu', value: 55 },
  { day: 'Fri', value: 90 },
  { day: 'Sat', value: 70 },
  { day: 'Sun', value: 85 },
];

const ACTIVITY_FEED = [
  { text: 'New order placed', detail: '#JD-2045 by Rahul Sharma', time: '2 min ago', type: 'order' },
  { text: 'Payment received', detail: '₹2,999 for order #JD-2044', time: '15 min ago', type: 'payment' },
  { text: 'Product review', detail: '5★ review on Premium Black Hoodie', time: '1 hr ago', type: 'review' },
  { text: 'New customer signup', detail: 'Sneha Reddy joined', time: '2 hrs ago', type: 'user' },
  { text: 'Stock alert', detail: 'Cargo Joggers - Khaki (only 5 left)', time: '3 hrs ago', type: 'alert' },
];

function getStatusStyle(status: string) {
  switch (status) {
    case 'Delivered': return { bg: 'rgba(34,197,94,0.1)', color: '#22c55e', border: 'rgba(34,197,94,0.2)' };
    case 'Shipped': return { bg: 'rgba(59,130,246,0.1)', color: '#3b82f6', border: 'rgba(59,130,246,0.2)' };
    case 'Processing': return { bg: 'rgba(249,115,22,0.1)', color: '#f97316', border: 'rgba(249,115,22,0.2)' };
    case 'Cancelled': return { bg: 'rgba(239,68,68,0.1)', color: '#ef4444', border: 'rgba(239,68,68,0.2)' };
    default: return { bg: 'rgba(107,114,128,0.1)', color: '#6b7280', border: 'rgba(107,114,128,0.2)' };
  }
}

export default function AdminDashboard() {
  const navigate = useNavigate();
  const [activeSidebar, setActiveSidebar] = useState('Dashboard');
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  // Check auth
  useEffect(() => {
    const auth = localStorage.getItem('jd_admin_auth');
    if (!auth) {
      navigate('/admin');
    }
  }, [navigate]);

  const handleLogout = () => {
    localStorage.removeItem('jd_admin_auth');
    navigate('/admin');
  };

  const containerVariants = {
    hidden: { opacity: 0 },
    visible: { opacity: 1, transition: { staggerChildren: 0.06 } },
  };

  const itemVariants = {
    hidden: { opacity: 0, y: 20 },
    visible: { opacity: 1, y: 0, transition: { duration: 0.5, ease: [0.16, 1, 0.3, 1] } },
  };

  return (
    <div className="min-h-screen flex" style={{ background: '#09090b', fontFamily: "'Inter', sans-serif" }}>

      {/* Desktop Sidebar */}
      <aside className="hidden lg:flex flex-col w-72 border-r border-white/5 p-6 sticky top-0 h-screen"
        style={{ background: 'rgba(255,255,255,0.02)' }}
      >
        {/* Brand */}
        <div className="flex items-center gap-3 mb-10">
          <div className="w-10 h-10 rounded-xl flex items-center justify-center"
            style={{ background: 'linear-gradient(135deg, #6366f1, #a855f7)' }}
          >
            <span className="text-white font-black text-sm">JD</span>
          </div>
          <div>
            <h2 className="text-white font-bold text-sm">JD's Fashion</h2>
            <p className="text-gray-500 text-xs">Admin Console</p>
          </div>
        </div>

        {/* Nav Items */}
        <nav className="flex-1 space-y-1">
          {SIDEBAR_ITEMS.map(item => (
            <button
              key={item.label}
              onClick={() => setActiveSidebar(item.label)}
              className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-all ${
                activeSidebar === item.label
                  ? 'text-white'
                  : 'text-gray-500 hover:text-gray-300 hover:bg-white/[0.03]'
              }`}
              style={activeSidebar === item.label ? {
                background: 'linear-gradient(135deg, rgba(99,102,241,0.15), rgba(168,85,247,0.1))',
                boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.05)',
              } : {}}
            >
              <item.icon size={18} />
              {item.label}
              {activeSidebar === item.label && (
                <motion.div
                  layoutId="sidebar-indicator"
                  className="ml-auto w-1.5 h-1.5 rounded-full"
                  style={{ background: '#6366f1' }}
                />
              )}
            </button>
          ))}
        </nav>

        {/* Logout */}
        <button
          onClick={handleLogout}
          className="flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium text-gray-500 hover:text-red-400 hover:bg-red-500/5 transition-all"
        >
          <LogOut size={18} />
          Sign Out
        </button>
      </aside>

      {/* Mobile Menu Overlay */}
      <AnimatePresence>
        {mobileMenuOpen && (
          <>
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setMobileMenuOpen(false)}
              className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 lg:hidden"
            />
            <motion.aside
              initial={{ x: -300 }}
              animate={{ x: 0 }}
              exit={{ x: -300 }}
              transition={{ type: 'spring', stiffness: 300, damping: 30 }}
              className="fixed left-0 top-0 bottom-0 w-72 z-50 lg:hidden flex flex-col p-6 border-r border-white/5"
              style={{ background: '#0a0a0c' }}
            >
              <div className="flex items-center justify-between mb-10">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl flex items-center justify-center"
                    style={{ background: 'linear-gradient(135deg, #6366f1, #a855f7)' }}
                  >
                    <span className="text-white font-black text-sm">JD</span>
                  </div>
                  <h2 className="text-white font-bold text-sm">JD's Fashion</h2>
                </div>
                <button onClick={() => setMobileMenuOpen(false)} className="text-gray-500 hover:text-white">
                  <X size={20} />
                </button>
              </div>
              <nav className="flex-1 space-y-1">
                {SIDEBAR_ITEMS.map(item => (
                  <button
                    key={item.label}
                    onClick={() => { setActiveSidebar(item.label); setMobileMenuOpen(false); }}
                    className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-all ${
                      activeSidebar === item.label ? 'text-white bg-white/5' : 'text-gray-500 hover:text-gray-300'
                    }`}
                  >
                    <item.icon size={18} />
                    {item.label}
                  </button>
                ))}
              </nav>
              <button onClick={handleLogout} className="flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium text-gray-500 hover:text-red-400 transition-all">
                <LogOut size={18} />
                Sign Out
              </button>
            </motion.aside>
          </>
        )}
      </AnimatePresence>

      {/* Main Content */}
      <main className="flex-1 overflow-auto">
        {/* Top Bar */}
        <header className="sticky top-0 z-40 px-6 py-4 flex items-center justify-between border-b border-white/5"
          style={{ background: 'rgba(9,9,11,0.8)', backdropFilter: 'blur(20px)' }}
        >
          <div className="flex items-center gap-4">
            <button onClick={() => setMobileMenuOpen(true)} className="lg:hidden text-gray-400 hover:text-white">
              <Menu size={22} />
            </button>
            <div>
              <h1 className="text-lg font-bold text-white">Dashboard</h1>
              <p className="text-xs text-gray-500">Welcome back, Admin</p>
            </div>
          </div>
          <div className="flex items-center gap-3">
            {/* Search */}
            <div className="hidden sm:flex items-center gap-2 px-4 py-2 rounded-xl border border-white/5 text-gray-500 text-sm"
              style={{ background: 'rgba(255,255,255,0.03)' }}
            >
              <Search size={14} />
              <span>Search...</span>
            </div>
            {/* Notification Bell */}
            <button className="relative p-2.5 rounded-xl border border-white/5 text-gray-400 hover:text-white transition-colors"
              style={{ background: 'rgba(255,255,255,0.03)' }}
            >
              <Bell size={18} />
              <span className="absolute top-1.5 right-1.5 w-2 h-2 rounded-full" style={{ background: '#6366f1' }} />
            </button>
            {/* Admin Avatar */}
            <div className="w-9 h-9 rounded-xl flex items-center justify-center text-xs font-bold text-white"
              style={{ background: 'linear-gradient(135deg, #6366f1, #a855f7)' }}
            >
              AD
            </div>
          </div>
        </header>

        {/* Dashboard Content */}
        <motion.div
          className="p-6 space-y-6"
          variants={containerVariants}
          initial="hidden"
          animate="visible"
        >
          {/* Stats Cards */}
          <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
            {STATS.map((stat, idx) => (
              <motion.div
                key={stat.label}
                variants={itemVariants}
                className="p-5 rounded-2xl border border-white/5 group hover:border-white/10 transition-all"
                style={{
                  background: 'rgba(255,255,255,0.02)',
                }}
              >
                <div className="flex items-center justify-between mb-4">
                  <div className="w-10 h-10 rounded-xl flex items-center justify-center"
                    style={{ background: `${stat.color}15`, color: stat.color }}
                  >
                    <stat.icon size={20} />
                  </div>
                  <div className={`flex items-center gap-1 text-xs font-semibold px-2 py-1 rounded-lg ${
                    stat.trend === 'up' ? 'text-emerald-400' : 'text-red-400'
                  }`}
                    style={{ background: stat.trend === 'up' ? 'rgba(34,197,94,0.1)' : 'rgba(239,68,68,0.1)' }}
                  >
                    {stat.trend === 'up' ? <TrendingUp size={12} /> : <TrendingDown size={12} />}
                    {stat.change}
                  </div>
                </div>
                <p className="text-2xl font-black text-white mb-1">{stat.value}</p>
                <p className="text-xs text-gray-500 font-medium">{stat.label}</p>
              </motion.div>
            ))}
          </div>

          {/* Chart + Activity Feed Row */}
          <div className="grid grid-cols-1 xl:grid-cols-3 gap-4">
            {/* Revenue Chart */}
            <motion.div
              variants={itemVariants}
              className="xl:col-span-2 p-6 rounded-2xl border border-white/5"
              style={{ background: 'rgba(255,255,255,0.02)' }}
            >
              <div className="flex items-center justify-between mb-6">
                <div>
                  <h3 className="text-sm font-bold text-white">Revenue Overview</h3>
                  <p className="text-xs text-gray-500 mt-1">Last 7 days</p>
                </div>
                <div className="flex items-center gap-2">
                  <button className="px-3 py-1.5 rounded-lg text-xs font-semibold text-white border border-white/10"
                    style={{ background: 'rgba(99,102,241,0.15)' }}
                  >
                    Weekly
                  </button>
                  <button className="px-3 py-1.5 rounded-lg text-xs font-semibold text-gray-500 hover:text-gray-300 transition-colors">
                    Monthly
                  </button>
                </div>
              </div>
              {/* Bar Chart */}
              <div className="flex items-end gap-3 h-48">
                {CHART_DATA.map((bar, idx) => (
                  <div key={bar.day} className="flex-1 flex flex-col items-center gap-2">
                    <motion.div
                      initial={{ height: 0 }}
                      animate={{ height: `${bar.value}%` }}
                      transition={{ delay: idx * 0.08, duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
                      className="w-full rounded-lg relative group cursor-pointer"
                      style={{
                        background: idx === 4
                          ? 'linear-gradient(180deg, #6366f1, #4f46e5)'
                          : 'linear-gradient(180deg, rgba(99,102,241,0.3), rgba(99,102,241,0.1))',
                        minHeight: '8px',
                      }}
                    >
                      {/* Tooltip on hover */}
                      <div className="absolute -top-8 left-1/2 -translate-x-1/2 px-2 py-1 rounded-md text-[10px] font-bold text-white opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap"
                        style={{ background: '#1e1e2e' }}
                      >
                        ₹{(bar.value * 1800).toLocaleString()}
                      </div>
                    </motion.div>
                    <span className="text-[11px] text-gray-500 font-medium">{bar.day}</span>
                  </div>
                ))}
              </div>
            </motion.div>

            {/* Activity Feed */}
            <motion.div
              variants={itemVariants}
              className="p-6 rounded-2xl border border-white/5"
              style={{ background: 'rgba(255,255,255,0.02)' }}
            >
              <div className="flex items-center justify-between mb-5">
                <h3 className="text-sm font-bold text-white">Recent Activity</h3>
                <button className="text-xs text-indigo-400 font-semibold hover:text-indigo-300">View All</button>
              </div>
              <div className="space-y-4">
                {ACTIVITY_FEED.map((activity, idx) => (
                  <motion.div
                    key={idx}
                    initial={{ opacity: 0, x: -10 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: 0.5 + idx * 0.1 }}
                    className="flex items-start gap-3"
                  >
                    <div className="mt-0.5 w-2 h-2 rounded-full flex-shrink-0"
                      style={{
                        background: activity.type === 'order' ? '#6366f1'
                          : activity.type === 'payment' ? '#22c55e'
                          : activity.type === 'review' ? '#f59e0b'
                          : activity.type === 'user' ? '#22d3ee'
                          : '#ef4444',
                      }}
                    />
                    <div className="flex-1 min-w-0">
                      <p className="text-xs text-white font-medium">{activity.text}</p>
                      <p className="text-[11px] text-gray-500 truncate">{activity.detail}</p>
                    </div>
                    <span className="text-[10px] text-gray-600 whitespace-nowrap">{activity.time}</span>
                  </motion.div>
                ))}
              </div>
            </motion.div>
          </div>

          {/* Orders Table + Top Products Row */}
          <div className="grid grid-cols-1 xl:grid-cols-3 gap-4">
            {/* Recent Orders */}
            <motion.div
              variants={itemVariants}
              className="xl:col-span-2 rounded-2xl border border-white/5 overflow-hidden"
              style={{ background: 'rgba(255,255,255,0.02)' }}
            >
              <div className="p-6 pb-4 flex items-center justify-between">
                <div>
                  <h3 className="text-sm font-bold text-white">Recent Orders</h3>
                  <p className="text-xs text-gray-500 mt-1">Latest transactions</p>
                </div>
                <div className="flex items-center gap-2">
                  <button className="p-2 rounded-lg border border-white/5 text-gray-500 hover:text-white transition-colors"
                    style={{ background: 'rgba(255,255,255,0.03)' }}
                  >
                    <Filter size={14} />
                  </button>
                  <button className="px-3 py-1.5 rounded-lg text-xs font-semibold text-indigo-400 border border-indigo-500/20 hover:bg-indigo-500/10 transition-colors">
                    View All
                  </button>
                </div>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead>
                    <tr className="border-t border-white/5">
                      <th className="px-6 py-3 text-left text-[11px] font-semibold text-gray-500 uppercase tracking-wider">Order</th>
                      <th className="px-6 py-3 text-left text-[11px] font-semibold text-gray-500 uppercase tracking-wider">Customer</th>
                      <th className="px-6 py-3 text-left text-[11px] font-semibold text-gray-500 uppercase tracking-wider hidden md:table-cell">Product</th>
                      <th className="px-6 py-3 text-left text-[11px] font-semibold text-gray-500 uppercase tracking-wider">Amount</th>
                      <th className="px-6 py-3 text-left text-[11px] font-semibold text-gray-500 uppercase tracking-wider">Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {RECENT_ORDERS.map((order, idx) => {
                      const statusStyle = getStatusStyle(order.status);
                      return (
                        <motion.tr
                          key={order.id}
                          initial={{ opacity: 0 }}
                          animate={{ opacity: 1 }}
                          transition={{ delay: 0.3 + idx * 0.05 }}
                          className="border-t border-white/5 hover:bg-white/[0.02] transition-colors cursor-pointer"
                        >
                          <td className="px-6 py-4 text-xs text-indigo-400 font-semibold">{order.id}</td>
                          <td className="px-6 py-4">
                            <div className="flex items-center gap-3">
                              <div className="w-8 h-8 rounded-lg flex items-center justify-center text-[10px] font-bold text-white"
                                style={{ background: 'linear-gradient(135deg, #374151, #1f2937)' }}
                              >
                                {order.avatar}
                              </div>
                              <div>
                                <p className="text-xs text-white font-medium">{order.customer}</p>
                                <p className="text-[11px] text-gray-500">{order.date}</p>
                              </div>
                            </div>
                          </td>
                          <td className="px-6 py-4 text-xs text-gray-400 hidden md:table-cell">{order.product}</td>
                          <td className="px-6 py-4 text-xs text-white font-semibold">{order.amount}</td>
                          <td className="px-6 py-4">
                            <span className="text-[11px] font-semibold px-2.5 py-1 rounded-lg"
                              style={{ background: statusStyle.bg, color: statusStyle.color, border: `1px solid ${statusStyle.border}` }}
                            >
                              {order.status}
                            </span>
                          </td>
                        </motion.tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </motion.div>

            {/* Top Products */}
            <motion.div
              variants={itemVariants}
              className="p-6 rounded-2xl border border-white/5"
              style={{ background: 'rgba(255,255,255,0.02)' }}
            >
              <div className="flex items-center justify-between mb-5">
                <h3 className="text-sm font-bold text-white">Top Products</h3>
                <button className="text-xs text-indigo-400 font-semibold hover:text-indigo-300">View All</button>
              </div>
              <div className="space-y-4">
                {TOP_PRODUCTS.map((product, idx) => (
                  <motion.div
                    key={product.name}
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.6 + idx * 0.1 }}
                    className="flex items-center gap-3 p-3 rounded-xl hover:bg-white/[0.03] transition-colors cursor-pointer group"
                  >
                    <img
                      src={product.image}
                      alt={product.name}
                      className="w-12 h-12 rounded-xl object-cover"
                      style={{ border: '1px solid rgba(255,255,255,0.05)' }}
                    />
                    <div className="flex-1 min-w-0">
                      <p className="text-xs text-white font-medium truncate">{product.name}</p>
                      <div className="flex items-center gap-2 mt-1">
                        <span className="flex items-center gap-0.5 text-[11px] text-yellow-500">
                          <Star size={10} className="fill-yellow-500" />
                          {product.rating}
                        </span>
                        <span className="text-[10px] text-gray-600">•</span>
                        <span className="text-[11px] text-gray-500">{product.sales} sold</span>
                      </div>
                    </div>
                    <div className="text-right">
                      <p className="text-xs text-white font-semibold">{product.revenue}</p>
                      <ChevronRight size={14} className="text-gray-600 ml-auto mt-1 group-hover:text-gray-400 transition-colors" />
                    </div>
                  </motion.div>
                ))}
              </div>
            </motion.div>
          </div>

          {/* Quick Stats Footer */}
          <motion.div
            variants={itemVariants}
            className="grid grid-cols-2 sm:grid-cols-4 gap-4"
          >
            {[
              { label: 'Pending Orders', value: '23', color: '#f59e0b' },
              { label: 'Returns Requested', value: '8', color: '#ef4444' },
              { label: 'Out of Stock', value: '12', color: '#f97316' },
              { label: 'New Reviews', value: '47', color: '#22c55e' },
            ].map((item) => (
              <div key={item.label} className="p-4 rounded-2xl border border-white/5 text-center"
                style={{ background: 'rgba(255,255,255,0.02)' }}
              >
                <p className="text-2xl font-black mb-1" style={{ color: item.color }}>{item.value}</p>
                <p className="text-[11px] text-gray-500 font-medium">{item.label}</p>
              </div>
            ))}
          </motion.div>
        </motion.div>
      </main>
    </div>
  );
}
