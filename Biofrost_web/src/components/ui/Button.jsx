import { forwardRef } from 'react';

const variants = {
  primary: 'bg-gray-900 text-white hover:bg-gray-800 active:bg-gray-950 focus:outline-none focus:ring-2 focus:ring-gray-300 focus:ring-offset-2',
  secondary: 'bg-gray-100 text-gray-900 hover:bg-gray-200 active:bg-gray-300 focus:outline-none focus:ring-2 focus:ring-gray-300 focus:ring-offset-2',
  ghost: 'bg-transparent text-gray-900 hover:bg-gray-50 active:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-gray-300 focus:ring-offset-2',
  outline: 'bg-transparent border-2 border-gray-200 text-gray-900 hover:border-gray-300 hover:bg-gray-50 active:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-gray-300',
  danger: 'bg-red-50 text-red-600 hover:bg-red-100 active:bg-red-200 focus:outline-none focus:ring-2 focus:ring-red-300 focus:ring-offset-2',
};

const sizes = {
  xs: 'px-3 py-1.5 text-xs font-medium',
  sm: 'px-3 py-2 text-sm font-medium',
  md: 'px-4 py-2.5 text-base font-semibold',
  lg: 'px-6 py-3 text-lg font-semibold',
  xl: 'px-8 py-3.5 text-lg font-semibold',
};

export const Button = forwardRef(({
  children,
  variant = 'primary',
  size = 'md',
  className = '',
  disabled = false,
  loading = false,
  icon,
  iconPosition = 'left',
  fullWidth = false,
  ...props
}, ref) => {
  const variantClass = variants[variant] || variants.primary;
  const sizeClass = sizes[size] || sizes.md;

  const icon_element = loading ? (
    <div className="w-4 h-4 border-2 border-current border-t-transparent rounded-full animate-spin" />
  ) : icon ? (
    <span className="flex-shrink-0">{icon}</span>
  ) : null;

  return (
    <button
      ref={ref}
      disabled={disabled || loading}
      className={`
        inline-flex items-center justify-center gap-2
        rounded-lg
        transition-all duration-200
        disabled:opacity-50 disabled:cursor-not-allowed
        active:scale-[0.98]
        ${variantClass}
        ${sizeClass}
        ${fullWidth ? 'w-full' : ''}
        ${className}
      `}
      {...props}
    >
      {iconPosition === 'left' && icon_element}
      {children}
      {iconPosition === 'right' && icon_element}
    </button>
  );
});

Button.displayName = 'Button';
