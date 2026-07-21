import { useEffect, useState } from 'react'

const useDebouncedValue = (value, delay = 400) => {
  const [debouncedValue, setDebouncedValue] = useState(value)

  useEffect(() => {
    const debounceTimer = window.setTimeout(() => {
      setDebouncedValue(value)
    }, delay)

    return () => window.clearTimeout(debounceTimer)
  }, [delay, value])

  return debouncedValue
}

export default useDebouncedValue
