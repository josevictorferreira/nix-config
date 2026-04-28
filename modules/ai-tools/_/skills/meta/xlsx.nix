{ lib
, pkgs
, isDarwin
, npx
, defaultBrowser
, kebabToHuman
, ...
}:
let
  skillDir = ./_xlsx;
  prompt = builtins.readFile (skillDir + "/_body.md");
in
{
  name = "xlsx";
  description = "Use this skill any time a spreadsheet file is the primary input or output. This means any task where the user wants to: open, read, edit, or fix an existing .xlsx, .xlsm, .csv, or .tsv file (e.g., adding columns, computing formulas, formatting, charting, cleaning messy data); create a new spreadsheet from scratch or from other data sources; or convert between tabular file formats. Trigger especially when the user references a spreadsheet file by name or path — even casually (like \"the xlsx in my downloads\") — and wants something done to it or produced from it. Also trigger for cleaning or restructuring messy tabular data files (malformed rows, misplaced headers, junk data) into proper spreadsheets. The deliverable must be a spreadsheet file. Do NOT trigger when the primary deliverable is a Word document, HTML report, standalone Python script, database pipeline, or Google Sheets API integration, even if tabular data is involved.";
  allowed-tools = [
    "Read"
    "Write"
    "Edit"
    "Bash"
    "Glob"
    "Grep"
  ];
  scripts = {
    "recalc.py" = builtins.readFile (skillDir + "/scripts/recalc.py");
    "office/pack.py" = builtins.readFile (skillDir + "/scripts/office/pack.py");
    "office/soffice.py" = builtins.readFile (skillDir + "/scripts/office/soffice.py");
    "office/unpack.py" = builtins.readFile (skillDir + "/scripts/office/unpack.py");
    "office/validate.py" = builtins.readFile (skillDir + "/scripts/office/validate.py");
    "office/helpers/__init__.py" = builtins.readFile (skillDir + "/scripts/office/helpers/__init__.py");
    "office/helpers/merge_runs.py" = builtins.readFile (
      skillDir + "/scripts/office/helpers/merge_runs.py"
    );
    "office/helpers/simplify_redlines.py" = builtins.readFile (
      skillDir + "/scripts/office/helpers/simplify_redlines.py"
    );
    "office/validators/__init__.py" = builtins.readFile (
      skillDir + "/scripts/office/validators/__init__.py"
    );
    "office/validators/base.py" = builtins.readFile (skillDir + "/scripts/office/validators/base.py");
    "office/validators/docx.py" = builtins.readFile (skillDir + "/scripts/office/validators/docx.py");
    "office/validators/pptx.py" = builtins.readFile (skillDir + "/scripts/office/validators/pptx.py");
    "office/validators/redlining.py" = builtins.readFile (
      skillDir + "/scripts/office/validators/redlining.py"
    );
    "office/schemas/mce/mc.xsd" = builtins.readFile (skillDir + "/scripts/office/schemas/mce/mc.xsd");
    "office/schemas/ecma/fouth-edition/opc-contentTypes.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/ecma/fouth-edition/opc-contentTypes.xsd"
    );
    "office/schemas/ecma/fouth-edition/opc-coreProperties.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/ecma/fouth-edition/opc-coreProperties.xsd"
    );
    "office/schemas/ecma/fouth-edition/opc-digSig.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/ecma/fouth-edition/opc-digSig.xsd"
    );
    "office/schemas/ecma/fouth-edition/opc-relationships.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/ecma/fouth-edition/opc-relationships.xsd"
    );
    "office/schemas/ISO-IEC29500-4_2016/dml-chart.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/ISO-IEC29500-4_2016/dml-chart.xsd"
    );
    "office/schemas/ISO-IEC29500-4_2016/dml-chartDrawing.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/ISO-IEC29500-4_2016/dml-chartDrawing.xsd"
    );
    "office/schemas/ISO-IEC29500-4_2016/dml-diagram.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/ISO-IEC29500-4_2016/dml-diagram.xsd"
    );
    "office/schemas/ISO-IEC29500-4_2016/dml-lockedCanvas.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/ISO-IEC29500-4_2016/dml-lockedCanvas.xsd"
    );
    "office/schemas/ISO-IEC29500-4_2016/dml-main.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/ISO-IEC29500-4_2016/dml-main.xsd"
    );
    "office/schemas/ISO-IEC29500-4_2016/dml-picture.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/ISO-IEC29500-4_2016/dml-picture.xsd"
    );
    "office/schemas/ISO-IEC29500-4_2016/dml-spreadsheetDrawing.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/ISO-IEC29500-4_2016/dml-spreadsheetDrawing.xsd"
    );
    "office/schemas/ISO-IEC29500-4_2016/dml-wordprocessingDrawing.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/ISO-IEC29500-4_2016/dml-wordprocessingDrawing.xsd"
    );
    "office/schemas/ISO-IEC29500-4_2016/pml.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/ISO-IEC29500-4_2016/pml.xsd"
    );
    "office/schemas/ISO-IEC29500-4_2016/shared-additionalCharacteristics.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/ISO-IEC29500-4_2016/shared-additionalCharacteristics.xsd"
    );
    "office/schemas/ISO-IEC29500-4_2016/shared-bibliography.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/ISO-IEC29500-4_2016/shared-bibliography.xsd"
    );
    "office/schemas/ISO-IEC29500-4_2016/shared-commonSimpleTypes.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/ISO-IEC29500-4_2016/shared-commonSimpleTypes.xsd"
    );
    "office/schemas/ISO-IEC29500-4_2016/shared-customXmlDataProperties.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/ISO-IEC29500-4_2016/shared-customXmlDataProperties.xsd"
    );
    "office/schemas/ISO-IEC29500-4_2016/shared-customXmlSchemaProperties.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/ISO-IEC29500-4_2016/shared-customXmlSchemaProperties.xsd"
    );
    "office/schemas/ISO-IEC29500-4_2016/shared-documentPropertiesCustom.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/ISO-IEC29500-4_2016/shared-documentPropertiesCustom.xsd"
    );
    "office/schemas/ISO-IEC29500-4_2016/shared-documentPropertiesExtended.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/ISO-IEC29500-4_2016/shared-documentPropertiesExtended.xsd"
    );
    "office/schemas/ISO-IEC29500-4_2016/shared-documentPropertiesVariantTypes.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/ISO-IEC29500-4_2016/shared-documentPropertiesVariantTypes.xsd"
    );
    "office/schemas/ISO-IEC29500-4_2016/shared-math.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/ISO-IEC29500-4_2016/shared-math.xsd"
    );
    "office/schemas/ISO-IEC29500-4_2016/shared-relationshipReference.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/ISO-IEC29500-4_2016/shared-relationshipReference.xsd"
    );
    "office/schemas/ISO-IEC29500-4_2016/sml.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/ISO-IEC29500-4_2016/sml.xsd"
    );
    "office/schemas/ISO-IEC29500-4_2016/vml-main.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/ISO-IEC29500-4_2016/vml-main.xsd"
    );
    "office/schemas/ISO-IEC29500-4_2016/vml-officeDrawing.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/ISO-IEC29500-4_2016/vml-officeDrawing.xsd"
    );
    "office/schemas/ISO-IEC29500-4_2016/vml-presentationDrawing.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/ISO-IEC29500-4_2016/vml-presentationDrawing.xsd"
    );
    "office/schemas/ISO-IEC29500-4_2016/vml-spreadsheetDrawing.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/ISO-IEC29500-4_2016/vml-spreadsheetDrawing.xsd"
    );
    "office/schemas/ISO-IEC29500-4_2016/vml-wordprocessingDrawing.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/ISO-IEC29500-4_2016/vml-wordprocessingDrawing.xsd"
    );
    "office/schemas/ISO-IEC29500-4_2016/wml.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/ISO-IEC29500-4_2016/wml.xsd"
    );
    "office/schemas/ISO-IEC29500-4_2016/xml.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/ISO-IEC29500-4_2016/xml.xsd"
    );
    "office/schemas/microsoft/wml-2010.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/microsoft/wml-2010.xsd"
    );
    "office/schemas/microsoft/wml-2012.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/microsoft/wml-2012.xsd"
    );
    "office/schemas/microsoft/wml-2018.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/microsoft/wml-2018.xsd"
    );
    "office/schemas/microsoft/wml-cex-2018.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/microsoft/wml-cex-2018.xsd"
    );
    "office/schemas/microsoft/wml-cid-2016.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/microsoft/wml-cid-2016.xsd"
    );
    "office/schemas/microsoft/wml-sdtdatahash-2020.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/microsoft/wml-sdtdatahash-2020.xsd"
    );
    "office/schemas/microsoft/wml-symex-2015.xsd" = builtins.readFile (
      skillDir + "/scripts/office/schemas/microsoft/wml-symex-2015.xsd"
    );
  };
  inherit prompt;
}
