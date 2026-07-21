/**
 * Application Routes Configuration
 *
 * Defines all protected routes in the application using React lazy loading
 * for code splitting and performance optimization.
 *
 * Each route object contains:
 * - path: URL path for the route
 * - name: Human-readable name for breadcrumbs
 * - element: Lazy-loaded React component
 * - exact: (optional) Requires exact path match
 *
 * @module routes
 */

import React from 'react'

const Dashboard = React.lazy(() => import('./views/dashboard/Dashboard'))
const Categories = React.lazy(() => import('./views/categories/Categories'))
const Departments = React.lazy(() => import('./views/departments/Departments'))
const Reports = React.lazy(() => import('./views/reports/Reports'))
const Notifications = React.lazy(() => import('./views/notifications/Notifications'))
const AuditLogs = React.lazy(() => import('./views/audit-logs/AuditLogs'))
const Profile = React.lazy(() => import('./views/profile/Profile'))
const Page404 = React.lazy(() => import('./views/pages/page404/Page404'))

/**
 * Array of route configuration objects
 *
 * @type {Array<Object>}
 * @property {string} path - URL path pattern
 * @property {string} name - Display name for breadcrumbs and navigation
 * @property {React.LazyExoticComponent} element - Lazy-loaded component
 * @property {boolean} [exact] - Whether to match path exactly
 *
 * @example
 * // Route renders when URL matches '/dashboard'
 * { path: '/dashboard', name: 'Dashboard', element: Dashboard }
 *
 * @example
 * // Route with exact match required
 * { path: '/base', name: 'Base', element: Cards, exact: true }
 */
export const routes = [
  { path: '/', exact: true, name: 'Home' },
  { path: '/dashboard', name: 'Dashboard', element: Dashboard },
  { path: '/categories', name: 'Categories', element: Categories },
  { path: '/departments', name: 'Departments', element: Departments },
  { path: '/reports', name: 'Reports', element: Reports },
  { path: '/notifications', name: 'Notifications', element: Notifications },
  { path: '/audit-logs', name: 'Audit Logs', element: AuditLogs },
  { path: '/profile', name: 'Profile', element: Profile },
  { path: '*', name: 'Not Found', element: Page404 },
]

export default routes
