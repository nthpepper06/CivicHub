/**
 * Sidebar Navigation Configuration
 *
 * Defines the structure and content of the sidebar navigation menu.
 * Supports multiple navigation component types from CoreUI React:
 * - CNavItem: Single navigation link
 * - CNavGroup: Collapsible group of links
 * - CNavTitle: Section title/divider
 *
 * @module _nav
 */

import CIcon from '@coreui/icons-react'
import {
  cilBell,
  cilBuilding,
  cilDescription,
  cilInbox,
  cilPeople,
  cilSpeedometer,
  cilTags,
} from '@coreui/icons'
import { CNavItem } from '@coreui/react'

/**
 * Navigation menu structure array
 *
 * @type {Array<Object>}
 * @property {React.ComponentType} component - CoreUI nav component (CNavItem, CNavGroup, CNavTitle)
 * @property {string} name - Display text for the nav item
 * @property {string} [to] - Internal route path (for CNavItem with routing)
 * @property {string} [href] - External URL (for CNavItem with external links)
 * @property {React.ReactNode} [icon] - Icon element to display
 * @property {Object} [badge] - Optional badge configuration
 * @property {string} badge.color - Badge color (info, danger, success, etc.)
 * @property {string} badge.text - Badge text content
 * @property {Array<Object>} [items] - Child items for CNavGroup
 *
 * @example
 * // Simple navigation item
 * {
 *   component: CNavItem,
 *   name: 'Dashboard',
 *   to: '/dashboard',
 *   icon: <CIcon icon={cilSpeedometer} customClassName="nav-icon" />,
 * }
 *
 * @example
 * // Navigation group with children
 * {
 *   component: CNavGroup,
 *   name: 'Base',
 *   to: '/base',
 *   icon: <CIcon icon={cilPuzzle} customClassName="nav-icon" />,
 *   items: [
 *     {
 *       component: CNavItem,
 *       name: 'Cards',
 *       to: '/base/cards',
 *     },
 *   ],
 * }
 *
 * @example
 * // Section title
 * {
 *   component: CNavTitle,
 *   name: 'Theme',
 * }
 */
const _nav = [
  {
    component: CNavItem,
    name: 'Dashboard',
    to: '/dashboard',
    icon: <CIcon icon={cilSpeedometer} customClassName="nav-icon" />,
  },
  {
    component: CNavItem,
    name: 'Categories',
    to: '/categories',
    icon: <CIcon icon={cilTags} customClassName="nav-icon" />,
  },
  {
    component: CNavItem,
    name: 'Departments',
    to: '/departments',
    icon: <CIcon icon={cilBuilding} customClassName="nav-icon" />,
  },
  {
    component: CNavItem,
    name: 'Reports',
    to: '/reports',
    icon: <CIcon icon={cilInbox} customClassName="nav-icon" />,
  },
  {
    component: CNavItem,
    name: 'Notifications',
    to: '/notifications',
    icon: <CIcon icon={cilBell} customClassName="nav-icon" />,
  },
  {
    component: CNavItem,
    name: 'Audit Logs',
    to: '/audit-logs',
    icon: <CIcon icon={cilDescription} customClassName="nav-icon" />,
  },
  {
    component: CNavItem,
    name: 'Profile',
    to: '/profile',
    icon: <CIcon icon={cilPeople} customClassName="nav-icon" />,
  },
]

export default _nav
