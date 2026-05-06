enum FormFieldType {
  shortText,
  longText,
  number,
  date,
  select,
  multiSelect,
  trueFalse,
  singleChoice,
  multiChoice,
  label,
}

FormFieldType formFieldTypeFromString(String s) {
  switch (s) {
    case 'short_text': return FormFieldType.shortText;
    case 'long_text': return FormFieldType.longText;
    case 'number': return FormFieldType.number;
    case 'date': return FormFieldType.date;
    case 'select': return FormFieldType.select;
    case 'multi_select': return FormFieldType.multiSelect;
    case 'true_false': return FormFieldType.trueFalse;
    case 'single_choice': return FormFieldType.singleChoice;
    case 'multi_choice': return FormFieldType.multiChoice;
    case 'label': return FormFieldType.label;
    default: return FormFieldType.shortText;
  }
}

String formFieldTypeToString(FormFieldType t) {
  switch (t) {
    case FormFieldType.shortText: return 'short_text';
    case FormFieldType.longText: return 'long_text';
    case FormFieldType.number: return 'number';
    case FormFieldType.date: return 'date';
    case FormFieldType.select: return 'select';
    case FormFieldType.multiSelect: return 'multi_select';
    case FormFieldType.trueFalse: return 'true_false';
    case FormFieldType.singleChoice: return 'single_choice';
    case FormFieldType.multiChoice: return 'multi_choice';
    case FormFieldType.label: return 'label';
  }
}
