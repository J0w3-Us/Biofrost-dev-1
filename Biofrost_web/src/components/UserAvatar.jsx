import { useState } from 'react';

/**
 * UserAvatar — Reusable avatar component with safe fallback.
 * 
 * If `src` is provided and valid, renders the photo.
 * If `src` is missing, null, or the image fails to load, degrades gracefully
 * to showing the first letter of the user's name in a styled circle.
 * 
 * This prevents 400/500-like crashes for new users without photos.
 * 
 * @param {string} src - URL of the profile photo (can be null/undefined)
 * @param {string} name - User's display name (used for initial fallback)
 * @param {'xs'|'sm'|'md'|'lg'|'xl'} size - Size preset
 * @param {string} className - Extra CSS classes for the outer container
 * @param {string} ring - Optional ring/border color class
 */
export function UserAvatar({ src, name = 'U', size = 'md', className = '', ring = '' }) {
    const [imgError, setImgError] = useState(false);

    const initial = (name && name !== 'Usuario')
        ? name.replace(/^\d+\s+/, '').charAt(0).toUpperCase()
        : (name?.charAt(0)?.toUpperCase() || 'U');

    const sizeMap = {
        xs: 'w-6 h-6 text-[10px]',
        sm: 'w-8 h-8 text-xs',
        md: 'w-10 h-10 text-sm',
        lg: 'w-11 h-11 text-sm',
        xl: 'w-40 h-40 text-4xl',
    };

    const sizeClasses = sizeMap[size] || sizeMap.md;

    const showImage = src && !imgError;

    return (
        <div
            className={`
                ${sizeClasses} rounded-full overflow-hidden flex items-center justify-center
                font-bold shrink-0 select-none
                ${!showImage ? 'bg-slate-800 text-white' : ''}
                ${ring}
                ${className}
            `.trim()}
        >
            {showImage ? (
                <img
                    src={src}
                    alt={name || 'Avatar'}
                    className="w-full h-full object-cover"
                    onError={() => setImgError(true)}
                    referrerPolicy="no-referrer"
                />
            ) : (
                <span>{initial}</span>
            )}
        </div>
    );
}
