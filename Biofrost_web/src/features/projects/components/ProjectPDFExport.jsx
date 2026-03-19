import { useState } from 'react';
import { jsPDF } from 'jspdf';
import { Download, Loader2 } from 'lucide-react';
import QRCode from 'react-qr-code';

// Utility for defensive metadata parsing (same as CanvasEditor)
const getNormalizedMetadata = (metadata) => {
    if (!metadata) return {};
    if (typeof metadata === 'string') { try { return JSON.parse(metadata); } catch { return {}; } }
    return metadata;
};

const getTableData = (block) => {
    const meta = getNormalizedMetadata(block.metadata);
    let raw = meta?.table || meta?.Table;
    if (typeof raw === 'string') { try { raw = JSON.parse(raw); } catch { raw = null; } }
    if (!raw) return { rows: [], hasHeader: true };
    let rows = raw.rows || raw.Rows || [];
    if (Array.isArray(rows)) {
        rows = rows.map(row => {
            if (typeof row === 'string') { try { return JSON.parse(row); } catch { return [row]; } }
            return Array.isArray(row) ? row : [String(row)];
        });
    }
    const hasHeader = raw.hasHeader ?? raw.HasHeader ?? true;
    return { rows, hasHeader };
};

// Strip all HTML tags and decode basic entities
const stripHtml = (html) => {
    if (!html) return '';
    return html
        .replace(/<br\s*\/?>/gi, '\n')
        .replace(/<\/p>/gi, '\n')
        .replace(/<[^>]+>/g, '')
        .replace(/&amp;/g, '&')
        .replace(/&lt;/g, '<')
        .replace(/&gt;/g, '>')
        .replace(/&nbsp;/g, ' ')
        .replace(/&quot;/g, '"')
        .trim();
};

// Draw wrapped text and return the new Y position
const addWrappedText = (doc, text, x, y, maxWidth, lineHeight) => {
    const lines = doc.splitTextToSize(text, maxWidth);
    doc.text(lines, x, y);
    return y + lines.length * lineHeight;
};

export function ProjectPDFExportButton({ project, creadorNombre }) {
    const [isExporting, setIsExporting] = useState(false);

    const publicUrl = typeof window !== 'undefined' ? `${window.location.origin}/showcase` : 'https://integradorhub.com';

    const handleExportPDF = async () => {
        if (!project) return;
        setIsExporting(true);
        try {
            // Pre-fetch all image blocks as base64 so we can embed them in the PDF
            const blocks = project?.canvas || project?.canvasBlocks || [];
            const imageBlocks = Array.isArray(blocks) ? blocks.filter(b => b.type === 'image' && b.content) : [];
            const imageCache = {};
            await Promise.allSettled(
                imageBlocks.map(async (block) => {
                    try {
                        const resp = await fetch(block.content, { mode: 'cors' });
                        const blob = await resp.blob();
                        const base64 = await new Promise((res) => {
                            const reader = new FileReader();
                            reader.onloadend = () => res(reader.result);
                            reader.readAsDataURL(blob);
                        });
                        // Detect format from mime type
                        const mime = blob.type || 'image/jpeg';
                        const fmt = mime.includes('png') ? 'PNG' : mime.includes('gif') ? 'GIF' : 'JPEG';
                        imageCache[block.id] = { base64, fmt };
                    } catch { /* skip images that fail to load */ }
                })
            );

            const doc = new jsPDF({ orientation: 'portrait', unit: 'mm', format: 'a4' });
            const W = doc.internal.pageSize.getWidth();     // 210
            const H = doc.internal.pageSize.getHeight();    // 297
            const margin = 20;
            const contentW = W - margin * 2;
            let y = margin;

            const LINE_SM = 5;
            const LINE_MD = 6;
            const LINE_LG = 8;

            const newPage = () => {
                doc.addPage();
                y = margin;
            };

            const checkY = (needed = 10) => {
                if (y + needed > H - margin) newPage();
            };

            // ── HEADER ────────────────────────────────────────────────────
            doc.setFont('helvetica', 'bold');
            doc.setFontSize(22);
            doc.setTextColor(17, 24, 39);
            const titleLines = doc.splitTextToSize(project.titulo || 'Sin Título', contentW - 30);
            doc.text(titleLines, margin, y);
            y += titleLines.length * LINE_LG + 2;

            doc.setFont('helvetica', 'normal');
            doc.setFontSize(10);
            doc.setTextColor(107, 114, 128);
            doc.text(`${project.materia || ''} • Ciclo ${project.ciclo || ''}`, margin, y);
            y += LINE_MD;

            // Divider
            doc.setDrawColor(229, 231, 235);
            doc.setLineWidth(0.5);
            doc.line(margin, y, W - margin, y);
            y += 8;

            // ── INFO GRID ─────────────────────────────────────────────────
            // Left: Responsable
            doc.setFillColor(239, 246, 255);
            doc.roundedRect(margin, y, contentW / 2 - 3, 22, 3, 3, 'F');
            doc.setFont('helvetica', 'bold');
            doc.setFontSize(7);
            doc.setTextColor(59, 130, 246);
            doc.text('RESPONSABLE', margin + 4, y + 6);
            doc.setFont('helvetica', 'bold');
            doc.setFontSize(11);
            doc.setTextColor(31, 41, 55);
            doc.text(creadorNombre || 'N/A', margin + 4, y + 13);
            doc.setFont('helvetica', 'normal');
            doc.setFontSize(8);
            doc.setTextColor(107, 114, 128);
            doc.text('Líder de Proyecto', margin + 4, y + 19);

            // Right: Stack
            const rx = margin + contentW / 2 + 3;
            doc.setFillColor(249, 250, 251);
            doc.roundedRect(rx, y, contentW / 2 - 3, 22, 3, 3, 'F');
            doc.setFont('helvetica', 'bold');
            doc.setFontSize(7);
            doc.setTextColor(107, 114, 128);
            doc.text('TECNOLOGÍAS', rx + 4, y + 6);
            doc.setFont('helvetica', 'normal');
            doc.setFontSize(9);
            doc.setTextColor(55, 65, 81);
            const stack = (project.stackTecnologico || []).join(' • ') || 'No especificado';
            const stackLines = doc.splitTextToSize(stack, contentW / 2 - 10);
            doc.text(stackLines, rx + 4, y + 13);
            y += 28;

            // ── TEAM ──────────────────────────────────────────────────────
            if (project.members?.length > 0) {
                checkY(14);
                doc.setFont('helvetica', 'bold');
                doc.setFontSize(11);
                doc.setTextColor(17, 24, 39);
                doc.text('Equipo', margin, y);
                y += LINE_MD;
                doc.setDrawColor(229, 231, 235);
                doc.line(margin, y, W - margin, y);
                y += 5;

                doc.setFont('helvetica', 'normal');
                doc.setFontSize(9);
                project.members.forEach(m => {
                    checkY(6);
                    const name = m.nombre && m.nombre !== 'Usuario' ? m.nombre : m.email;
                    const role = m.rol || 'Miembro';
                    doc.setTextColor(55, 65, 81);
                    doc.text(`• ${name}`, margin + 3, y);
                    doc.setTextColor(107, 114, 128);
                    doc.text(role, W - margin - doc.getTextWidth(role), y);
                    y += LINE_SM + 1;
                });
                y += 4;
            }

            // ── CANVAS BLOCKS ─────────────────────────────────────────────
            const canvas = project?.canvas || project?.canvasBlocks || [];
            if (Array.isArray(canvas) && canvas.length > 0) {
                checkY(14);
                doc.setFont('helvetica', 'bold');
                doc.setFontSize(11);
                doc.setTextColor(17, 24, 39);
                doc.text('Detalles del Proyecto', margin, y);
                y += LINE_MD;
                doc.setDrawColor(229, 231, 235);
                doc.line(margin, y, W - margin, y);
                y += 6;

                for (const block of canvas) {
                    checkY(10);
                    const text = stripHtml(block.content || '');

                    switch (block.type) {
                        case 'h1':
                            doc.setFont('helvetica', 'bold');
                            doc.setFontSize(16);
                            doc.setTextColor(17, 24, 39);
                            y = addWrappedText(doc, text, margin, y, contentW, LINE_LG + 2);
                            y += 3;
                            break;

                        case 'h2':
                            checkY(12);
                            doc.setFont('helvetica', 'bold');
                            doc.setFontSize(13);
                            doc.setTextColor(31, 41, 55);
                            y = addWrappedText(doc, text, margin, y, contentW, LINE_LG);
                            y += 2;
                            break;

                        case 'h3':
                            checkY(10);
                            doc.setFont('helvetica', 'bold');
                            doc.setFontSize(11);
                            doc.setTextColor(55, 65, 81);
                            y = addWrappedText(doc, text, margin, y, contentW, LINE_MD);
                            y += 2;
                            break;

                        case 'quote':
                            checkY(8);
                            doc.setDrawColor(156, 163, 175);
                            doc.setLineWidth(1.5);
                            doc.line(margin, y - 1, margin, y + LINE_MD * doc.splitTextToSize(text, contentW - 8).length);
                            doc.setLineWidth(0.5);
                            doc.setFont('helvetica', 'italic');
                            doc.setFontSize(10);
                            doc.setTextColor(75, 85, 99);
                            y = addWrappedText(doc, text, margin + 5, y, contentW - 8, LINE_MD);
                            y += 3;
                            break;

                        case 'code':
                            checkY(10);
                            doc.setFillColor(243, 244, 246);
                            const codeLines = doc.splitTextToSize(block.content || '', contentW - 8);
                            doc.roundedRect(margin, y - 3, contentW, codeLines.length * LINE_SM + 8, 2, 2, 'F');
                            doc.setFont('courier', 'normal');
                            doc.setFontSize(8);
                            doc.setTextColor(31, 41, 55);
                            doc.text(codeLines, margin + 4, y + 2);
                            y += codeLines.length * LINE_SM + 9;
                            break;

                        case 'bullet':
                            checkY(6);
                            doc.setFont('helvetica', 'normal');
                            doc.setFontSize(10);
                            doc.setTextColor(55, 65, 81);
                            doc.text('•', margin + 2, y);
                            y = addWrappedText(doc, text, margin + 7, y, contentW - 7, LINE_MD);
                            y += 1;
                            break;

                        case 'todo':
                            checkY(6);
                            const metaTodo = getNormalizedMetadata(block.metadata);
                            doc.setDrawColor(209, 213, 219);
                            doc.setLineWidth(0.4);
                            doc.rect(margin + 1, y - 3.5, 4, 4);
                            if (metaTodo?.checked) {
                                doc.setFont('helvetica', 'bold');
                                doc.setFontSize(8);
                                doc.setTextColor(59, 130, 246);
                                doc.text('✓', margin + 1.5, y - 0.5);
                            }
                            doc.setFont('helvetica', 'normal');
                            doc.setFontSize(10);
                            doc.setTextColor(metaTodo?.checked ? 156 : 55, metaTodo?.checked ? 163 : 65, metaTodo?.checked ? 175 : 81);
                            y = addWrappedText(doc, text, margin + 8, y, contentW - 8, LINE_MD);
                            y += 1;
                            break;

                        case 'divider':
                            checkY(6);
                            doc.setDrawColor(229, 231, 235);
                            doc.setLineWidth(0.5);
                            doc.line(margin, y, W - margin, y);
                            y += 6;
                            break;

                        case 'table':
                            checkY(20);
                            const { rows, hasHeader } = getTableData(block);
                            if (!rows.length) break;

                            // Calculate column widths
                            const cols = rows[0]?.length || 1;
                            const colW = contentW / cols;

                            doc.setLineWidth(0.3);
                            doc.setDrawColor(209, 213, 219);

                            rows.forEach((row, ri) => {
                                checkY(8);
                                const cellH = 8;

                                if (hasHeader && ri === 0) {
                                    doc.setFillColor(249, 250, 251);
                                }

                                row.forEach((cell, ci) => {
                                    const cx = margin + ci * colW;
                                    if (hasHeader && ri === 0) {
                                        doc.setFillColor(249, 250, 251);
                                        doc.rect(cx, y - 4, colW, cellH, 'FD');
                                        doc.setFont('helvetica', 'bold');
                                    } else {
                                        doc.rect(cx, y - 4, colW, cellH, 'D');
                                        doc.setFont('helvetica', 'normal');
                                    }
                                    doc.setFontSize(9);
                                    doc.setTextColor(31, 41, 55);
                                    const cellText = doc.splitTextToSize(String(cell || ''), colW - 4);
                                    doc.text(cellText[0] || '', cx + 2, y);
                                });
                                y += cellH;
                            });
                            y += 4;
                            break;

                        case 'image': {
                            const cached = imageCache[block.id];
                            if (cached) {
                                try {
                                    // Calculate height proportionally to fit within page width
                                    const imgProps = doc.getImageProperties(cached.base64);
                                    const imgW = contentW;
                                    const imgH = (imgProps.height * imgW) / imgProps.width;
                                    const maxImgH = 120; // max 120mm tall
                                    const finalH = Math.min(imgH, maxImgH);
                                    checkY(finalH + 4);
                                    doc.addImage(cached.base64, cached.fmt, margin, y, imgW, finalH);
                                    y += finalH + 4;
                                } catch {
                                    doc.setFont('helvetica', 'italic');
                                    doc.setFontSize(8);
                                    doc.setTextColor(156, 163, 175);
                                    doc.text('[Imagen no disponible]', margin, y);
                                    y += LINE_MD;
                                }
                            } else if (block.content) {
                                doc.setFont('helvetica', 'italic');
                                doc.setFontSize(8);
                                doc.setTextColor(156, 163, 175);
                                doc.text('[Imagen adjunta]', margin, y);
                                y += LINE_MD;
                            }
                            break;
                        }

                        default: // text
                            if (!text) break;
                            checkY(6);
                            doc.setFont('helvetica', 'normal');
                            doc.setFontSize(10);
                            doc.setTextColor(75, 85, 99);
                            y = addWrappedText(doc, text, margin, y, contentW, LINE_MD);
                            y += 2;
                            break;
                    }
                }
            }

            // ── FOOTER ────────────────────────────────────────────────────
            const totalPages = doc.internal.getNumberOfPages();
            for (let p = 1; p <= totalPages; p++) {
                doc.setPage(p);
                doc.setDrawColor(229, 231, 235);
                doc.setLineWidth(0.4);
                doc.line(margin, H - 12, W - margin, H - 12);
                doc.setFont('helvetica', 'normal');
                doc.setFontSize(7);
                doc.setTextColor(156, 163, 175);
                doc.text('Generado por Byfrost • IntegradorHub', margin, H - 7);
                doc.text(`${p} / ${totalPages}`, W - margin, H - 7, { align: 'right' });
            }

            const safeName = `Proyecto_${(project.titulo || 'Export').replace(/[^a-zA-Z0-9\u00C0-\u024F\s_-]/g, '').replace(/\s+/g, '_')}.pdf`;
            doc.save(safeName);
        } catch (error) {
            console.error('Error exportando PDF:', error);
            alert(`Error al exportar: ${error.message || error}`);
        } finally {
            setIsExporting(false);
        }
    };

    if (!project) return null;

    return (
        <button
            onClick={handleExportPDF}
            disabled={isExporting}
            className="flex items-center justify-center gap-2 px-4 py-2 bg-gray-900 text-white text-sm font-bold rounded-xl shadow-md hover:bg-black transition-all disabled:opacity-70 disabled:cursor-wait"
        >
            {isExporting ? <Loader2 size={16} className="animate-spin" /> : <Download size={16} />}
            {isExporting ? 'Generando...' : 'Exportar PDF'}
        </button>
    );
}
