const variants = {
  default: 'bg-gray-100 text-gray-700',
  secondary: 'bg-gray-150 text-gray-600',
  muted: 'bg-gray-200 text-gray-500',
  dark: 'bg-gray-900 text-white',
  success: 'bg-green-50 text-green-700',
  warning: 'bg-yellow-50 text-yellow-700',
  error: 'bg-red-50 text-red-700',
};

export function Badge({ children, variant = 'default', size = 'md', className = '' }) {
  const sizeClasses = {
    sm: 'px-2 py-0.5 text-xs',
    md: 'px-2.5 py-1 text-xs',
    lg: 'px-3 py-1.5 text-sm',
  };

  return (
    <span className={`
      inline-flex items-center gap-1
      font-semibold
      rounded-full
      transition-colors duration-200
      ${variants[variant]}
      ${sizeClasses[size]}
      ${className}
    `}>
      {children}
    </span>
  );
}
