import { motion } from 'framer-motion'

export default function AnimatedCard({
  children,
  className = '',
  style = {},
  delay = 0,
  onClick,
  glowColor = 'rgba(34,211,238,0.18)',
  ...props
}) {
  return (
    <motion.div
      className={className}
      style={{ position: 'relative', ...style }}
      initial={{ opacity: 0, y: 18 }}
      animate={{ opacity: 1, y: 0  }}
      exit={{    opacity: 0, y: -10 }}
      transition={{ duration: 0.32, delay, ease: [0.25, 0.46, 0.45, 0.94] }}
      whileHover={{
        scale: 1.022,
        y: -4,
        boxShadow: `0 16px 40px ${glowColor}, 0 4px 16px rgba(0,0,0,0.22)`,
        transition: { duration: 0.22, ease: [0.25, 0.46, 0.45, 0.94] },
      }}
      whileTap={{
        scale: 0.97,
        boxShadow: `0 4px 12px rgba(0,0,0,0.30)`,
        transition: { duration: 0.12 },
      }}
      onClick={onClick}
      {...props}
    >
      {children}
    </motion.div>
  )
}
