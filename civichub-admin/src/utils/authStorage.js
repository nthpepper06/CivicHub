const ACCESS_TOKEN_KEY = 'civichub_admin_access_token'
const USER_KEY = 'civichub_admin_user'

const storageTargets = [localStorage, sessionStorage]

export const getAccessToken = () =>
  localStorage.getItem(ACCESS_TOKEN_KEY) || sessionStorage.getItem(ACCESS_TOKEN_KEY)

export const setAccessToken = (token, rememberMe = false) => {
  const storage = rememberMe ? localStorage : sessionStorage
  const otherStorage = rememberMe ? sessionStorage : localStorage

  otherStorage.removeItem(ACCESS_TOKEN_KEY)
  storage.setItem(ACCESS_TOKEN_KEY, token)
}

export const removeAccessToken = () => {
  storageTargets.forEach((storage) => storage.removeItem(ACCESS_TOKEN_KEY))
}

export const getStoredUser = () => {
  const storedUser = localStorage.getItem(USER_KEY) || sessionStorage.getItem(USER_KEY)

  if (!storedUser) {
    return null
  }

  try {
    return JSON.parse(storedUser)
  } catch {
    clearAuthStorage()
    return null
  }
}

export const setStoredUser = (user, rememberMe = false) => {
  const storage = rememberMe ? localStorage : sessionStorage
  const otherStorage = rememberMe ? sessionStorage : localStorage

  otherStorage.removeItem(USER_KEY)
  storage.setItem(USER_KEY, JSON.stringify(user))
}

export const replaceStoredUser = (user) => {
  const storage = localStorage.getItem(USER_KEY) ? localStorage : sessionStorage

  if (getAccessToken()) {
    storage.setItem(USER_KEY, JSON.stringify(user))
  }
}

export const clearAuthStorage = () => {
  storageTargets.forEach((storage) => {
    storage.removeItem(ACCESS_TOKEN_KEY)
    storage.removeItem(USER_KEY)
  })
}
