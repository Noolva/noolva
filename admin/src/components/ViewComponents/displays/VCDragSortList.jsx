import React, { useMemo } from "react";
import { DndContext, closestCenter } from "@dnd-kit/core";
import { SortableContext, useSortable, verticalListSortingStrategy, arrayMove } from "@dnd-kit/sortable";
import { CSS } from "@dnd-kit/utilities";
import { List, Typography } from "antd";

const { Text } = Typography;

function SortableItem({ id, primary, secondary }) {
  const { attributes, listeners, setNodeRef, transform, transition, isDragging } = useSortable({ id });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    cursor: "grab",
    opacity: isDragging ? 0.6 : 1,
    background: isDragging ? "#fafafa" : undefined,
    borderRadius: 8,
  };

  return (
    <div ref={setNodeRef} style={style} {...attributes} {...listeners}>
      <List.Item style={{ padding: "10px 12px" }}>
        <List.Item.Meta
          title={<Text strong>{primary}</Text>}
          description={secondary ? <Text type="secondary">{secondary}</Text> : null}
        />
        <Text type="secondary">Drag</Text>
      </List.Item>
    </div>
  );
}

/**
 * VCDragSortList
 * A simple drag-and-drop sortable list using @dnd-kit (popular + maintained).
 *
 * Props:
 * - items: Array<{ id: string|number, primary: string, secondary?: string }>
 * - onReorder: (newItems) => void
 */
export function VCDragSortList({ items, onReorder }) {
  const ids = useMemo(() => items.map((i) => i.id), [items]);

  return (
    <DndContext
      collisionDetection={closestCenter}
      onDragEnd={({ active, over }) => {
        if (!over || active.id === over.id) return;
        const oldIndex = ids.indexOf(active.id);
        const newIndex = ids.indexOf(over.id);
        if (oldIndex < 0 || newIndex < 0) return;
        onReorder(arrayMove(items, oldIndex, newIndex));
      }}
    >
      <SortableContext items={ids} strategy={verticalListSortingStrategy}>
        <List
          bordered
          dataSource={items}
          renderItem={(item) => (
            <SortableItem id={item.id} primary={item.primary} secondary={item.secondary} />
          )}
        />
      </SortableContext>
    </DndContext>
  );
}

