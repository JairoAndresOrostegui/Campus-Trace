import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/form_template.dart';
import '../models/form_field_types.dart';

Future<void> generateAndPrintPdfs(
    FormTemplate template,
    Map<String, dynamic> answers,
) async {
  final pdf = pw.Document();

  // Load a font that supports a wide range of characters
  final font = await PdfGoogleFonts.poppinsRegular();
  final fontBold = await PdfGoogleFonts.poppinsBold();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        final List<pw.Widget> content = [];

        // Add form title and subtitle
        content.add(
          pw.Center(
            child: pw.Text(
              template.header.title,
              style: pw.TextStyle(
                fontSize: template.header.titleFontSize,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        );
        if ((template.header.subtitle ?? '').trim().isNotEmpty) {
          content.add(
            pw.Center(
              child: pw.Text(
                template.header.subtitle!,
                style: pw.TextStyle(
                  fontSize: template.header.subtitleFontSize,
                  font: font,
                ),
              ),
            ),
          );
        }

        // Add sections and fields
        for (final sec in template.sections) {
          content.add(pw.SizedBox(height: 16));
          content.add(
            pw.Header(
              level: 1,
              child: pw.Text(
                sec.title,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  font: fontBold,
                ),
              ),
            ),
          );

          for (final sub in sec.children) {
            content.add(pw.SizedBox(height: 8));
            if (sub.title.trim().isNotEmpty == true) {
              content.add(
                pw.Text(
                  sub.title,
                  style: pw.TextStyle(
                    fontSize: 12,
                    font: fontBold,
                  ),
                ),
              );
            }

            for (final field in sub.fields) {
              final label = field.label;
              final answer = answers[field.id];

              if (field.type == FormFieldType.label) {
                content.add(
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 8),
                    child: pw.Text(
                      label,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        font: fontBold,
                      ),
                    ),
                  ),
                );
                continue;
              }

              final answerText = _getAnswerText(field.type, answer);

              content.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 8),
                  child: pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: '$label: ',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            font: fontBold,
                            fontSize: 10,
                          ),
                        ),
                        pw.TextSpan(
                          text: answerText,
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
          }
        }
        return content;
      },
    ),
  );

  // Print or save the PDF
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
  );
}

String _getAnswerText(FormFieldType type, dynamic answer) {
  if (answer == null) return 'No respondido';
  
  switch (type) {
    case FormFieldType.date:
      return (answer is DateTime) ? answer.toString().split(' ')[0] : 'Error';
    case FormFieldType.multiSelect:
    case FormFieldType.multiChoice:
      return (answer is List) ? answer.join(', ') : 'Error';
    case FormFieldType.trueFalse:
      return (answer as bool) ? 'Sí' : 'No';
    default:
      return answer.toString();
  }
}