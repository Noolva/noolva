import { VCText } from "./inputs/VCText";
import { VCTextArea } from "./inputs/VCTextArea";
import { VCNumber } from "./inputs/VCNumber";
import { VCSelect } from "./inputs/VCSelect";
import { VCDate } from "./inputs/VCDate";
import { VCDateTime } from "./inputs/VCDateTime";
import { VCTimestampUTC } from "./inputs/VCTimestampUTC";
import { VCSwitch } from "./inputs/VCSwitch";
import { VCCheckbox } from "./inputs/VCCheckbox";
import { VCRadio } from "./inputs/VCRadio";
import { VCUpload } from "./inputs/VCUpload";
import { VCColor } from "./inputs/VCColor";
import { VCIconChooser } from "./inputs/VCIconChooser";
import { VCJsonEditor } from "./inputs/VCJsonEditor";

import { VCLabel } from "./displays/VCLabel";
import { VCJsonViewer } from "./displays/VCJsonViewer";
import { VCTable } from "./displays/VCTable";
import { VCStatistic } from "./displays/VCStatistic";
import { VCTag } from "./displays/VCTag";
import { VCBadge } from "./displays/VCBadge";
import { VCImage } from "./displays/VCImage";
import { VCLink } from "./displays/VCLink";
import { VCProgress } from "./displays/VCProgress";
import { VCTab } from "./displays/VCTab";
import { VCDrawer } from "./displays/VCDrawer";
import { VCModal } from "./displays/VCModal";
import { VCSkeleton } from "./displays/VCSkeleton";
import { VCIcon } from "./displays/VCIcon";

import { VCRow, VCColumn, VCDivider, VCForm, VCCard } from "../layoutComponents";

export const viewComponentRegistry = {
  // Layouts
  row: VCRow,
  column: VCColumn,
  divider: VCDivider,

  // Containers
  form: VCForm,
  card: VCCard,

  // Inputs
  text: VCText,
  textarea: VCTextArea,
  number: VCNumber,
  select: VCSelect,
  date: VCDate,
  datetime: VCDateTime,
  timestamp: VCTimestampUTC,
  timestamputc: VCTimestampUTC,
  switch: VCSwitch,
  checkbox: VCCheckbox,
  radio: VCRadio,
  upload: VCUpload,
  color: VCColor,
  iconchooser: VCIconChooser,
  icon_chooser: VCIconChooser,
  jsoneditor: VCJsonEditor,
  json_editor: VCJsonEditor,

  // Displays
  label: VCLabel,
  table: VCTable,
  statistic: VCStatistic,
  tag: VCTag,
  badge: VCBadge,
  image: VCImage,
  link: VCLink,
  progress: VCProgress,
  tab: VCTab,
  drawer: VCDrawer,
  modal: VCModal,
  skeleton: VCSkeleton,
  jsonviewer: VCJsonViewer,
  json_viewer: VCJsonViewer,
  icon: VCIcon,
};

