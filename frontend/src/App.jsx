import React, { useState } from 'react';
import { Routes, Route, Navigate, useLocation } from 'react-router-dom';
import { AnimatePresence, motion } from 'framer-motion';
import Sidebar from './components/layout/Sidebar.jsx';
import TopBar from './components/layout/TopBar.jsx';
import Dashboard from './pages/Dashboard.jsx';
import ProductsPage from './pages/ProductsPage.jsx';
import OrganicMaterialsPage from './pages/OrganicMaterialsPage.jsx';
import ProductionPage from './pages/ProductionPage.jsx';
import SalesPage from './pages/SalesPage.jsx';
import DataPage from './pages/DataPage.jsx';
import WilayahPage from './pages/WilayahPage.jsx';

const pageVariants = {
  initial: { opacity: 0 },
  enter:   { opacity: 1, transition: { duration: 0.15, ease: 'easeOut' } },
  exit:    { opacity: 0, transition: { duration: 0.1, ease: 'easeIn' } },
};

function PageWrap({ children }) {
  return <div className="page-content">{children}</div>;
}

export default function App() {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const location = useLocation();

  return (
    <div className="app-layout">
      {/* Mobile overlay */}
      <AnimatePresence>
        {sidebarOpen && (
          <motion.div
            key="overlay"
            className="sidebar-overlay lg:hidden"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.12 }}
            onClick={() => setSidebarOpen(false)}
          />
        )}
      </AnimatePresence>

      {/* Navigation */}
      <div
        className={`
          app-nav flex-shrink-0
          ${sidebarOpen ? '' : '-translate-x-full lg:translate-x-0'}
          fixed inset-y-0 left-0 z-40
          lg:relative lg:translate-x-0
          transition-transform duration-200 ease-out
        `}
      >
        <Sidebar onClose={() => setSidebarOpen(false)} />
      </div>

      {/* Main */}
      <div className="app-main flex flex-col min-w-0 flex-1 overflow-hidden">
        <TopBar onMenuToggle={() => setSidebarOpen(v => !v)} />
        <div className="flex-1 overflow-y-auto">
          <AnimatePresence mode="wait" initial={false}>
            <Routes location={location} key={location.pathname}>
              <Route path="/" element={<Navigate to="/dashboard" replace />} />
              <Route path="/dashboard" element={<PageWrap><Dashboard /></PageWrap>} />
              <Route path="/products" element={<PageWrap><ProductsPage /></PageWrap>} />
              <Route path="/organic-materials" element={<PageWrap><OrganicMaterialsPage /></PageWrap>} />
              <Route path="/production" element={<PageWrap><ProductionPage /></PageWrap>} />
              <Route path="/sales" element={<PageWrap><SalesPage /></PageWrap>} />
              <Route path="/wilayah" element={<PageWrap><WilayahPage /></PageWrap>} />
              <Route path="/data" element={<PageWrap><DataPage /></PageWrap>} />
            </Routes>
          </AnimatePresence>
        </div>
      </div>
    </div>
  );
}
