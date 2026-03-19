# ✏️ Módulo 07: Canvas Editor (Estilo Notion)

> **Objetivo:** Editor de bloques para documentar proyectos  
> **Complejidad:** 🔴 Alta  
> **Dependencias:** Módulo 05

---

## 🎯 Entregables

- [ ] Editor de bloques drag & drop
- [ ] Tipos: texto, heading, imagen, video, código
- [ ] Auto-guardado
- [ ] Vista previa

---

## 📦 Tipos de Bloques

| Tipo | Descripción |
|------|-------------|
| `heading` | Título H1, H2, H3 |
| `text` | Texto con markdown |
| `image` | Imagen con caption |
| `video` | Embed de YouTube |
| `code` | Bloque de código |

---

## 🔧 CanvasBlock Schema

```csharp
public class CanvasBlock
{
    public string Id { get; set; }
    public string Type { get; set; } // heading, text, image, video, code
    public string Content { get; set; }
    public int Order { get; set; }
    public Dictionary<string, object>? Metadata { get; set; }
}
```

---

## 🔧 Frontend: CanvasEditor

**CanvasEditor.jsx**
```jsx
import { useState, useCallback } from 'react';
import { DndContext, closestCenter } from '@dnd-kit/core';
import { SortableContext, verticalListSortingStrategy } from '@dnd-kit/sortable';

export function CanvasEditor({ projectId, initialBlocks }) {
  const [blocks, setBlocks] = useState(initialBlocks || []);

  const addBlock = (type) => {
    const newBlock = {
      id: crypto.randomUUID(),
      type,
      content: '',
      order: blocks.length
    };
    setBlocks([...blocks, newBlock]);
  };

  const updateBlock = (id, content) => {
    setBlocks(blocks.map(b => 
      b.id === id ? { ...b, content } : b
    ));
  };

  const deleteBlock = (id) => {
    setBlocks(blocks.filter(b => b.id !== id));
  };

  return (
    <div className="max-w-3xl mx-auto p-6">
      {/* Toolbar */}
      <div className="flex gap-2 mb-6 p-3 bg-gray-50 rounded-lg">
        <button onClick={() => addBlock('heading')}>📝 Título</button>
        <button onClick={() => addBlock('text')}>📄 Texto</button>
        <button onClick={() => addBlock('image')}>🖼️ Imagen</button>
        <button onClick={() => addBlock('video')}>🎬 Video</button>
        <button onClick={() => addBlock('code')}>💻 Código</button>
      </div>

      {/* Blocks */}
      <DndContext collisionDetection={closestCenter}>
        <SortableContext items={blocks.map(b => b.id)} strategy={verticalListSortingStrategy}>
          {blocks.map(block => (
            <BlockRenderer
              key={block.id}
              block={block}
              onUpdate={updateBlock}
              onDelete={deleteBlock}
            />
          ))}
        </SortableContext>
      </DndContext>
    </div>
  );
}
```

**BlockRenderer.jsx**
```jsx
export function BlockRenderer({ block, onUpdate, onDelete }) {
  switch (block.type) {
    case 'heading':
      return <HeadingBlock block={block} onUpdate={onUpdate} onDelete={onDelete} />;
    case 'text':
      return <TextBlock block={block} onUpdate={onUpdate} onDelete={onDelete} />;
    case 'image':
      return <ImageBlock block={block} onUpdate={onUpdate} onDelete={onDelete} />;
    case 'video':
      return <VideoBlock block={block} onUpdate={onUpdate} onDelete={onDelete} />;
    case 'code':
      return <CodeBlock block={block} onUpdate={onUpdate} onDelete={onDelete} />;
    default:
      return null;
  }
}
```

---

## 🔧 Backend: UpdateCanvas

**UpdateCanvasCommand.cs**
```csharp
public record UpdateCanvasCommand(
    string ProjectId,
    List<CanvasBlock> Blocks
) : IRequest<bool>;
```

**UpdateCanvasHandler.cs**
```csharp
public async Task<bool> Handle(UpdateCanvasCommand req, CancellationToken ct)
{
    await FirestoreContext.Projects
        .Document(req.ProjectId)
        .UpdateAsync(new Dictionary<string, object>
        {
            ["content_blocks"] = req.Blocks,
            ["fecha_actualizacion"] = DateTime.UtcNow
        });
    
    return true;
}
```

---

## ✅ Verificación

| Test | Esperado |
|------|----------|
| Agregar bloque | Aparece en lista |
| Editar texto | Contenido guardado |
| Reordenar | Orden persistido |

---

## ➡️ Siguiente: [Módulo 08: Evaluaciones](./08_EVALUACIONES.md)
