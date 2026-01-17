import { VCRow } from "./VCRow";
import { VCColumn } from "./VCColumn";
import { VCDivider } from "./VCDivider";
import { VCForm } from "./VCForm";
import { VCCard } from "./VCCard";

export const layoutComponentRegistry = {
  row: VCRow,
  column: VCColumn,
  divider: VCDivider,
  form: VCForm,
  card: VCCard,
};

export { VCRow, VCColumn, VCDivider, VCForm, VCCard };
