import 'dart:io';

void main() {
  final file = File('README.md');
  final lines = file.readAsLinesSync();

  // Find the exact spot to insert the backend
  int clinicalEndIndex = -1;
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains('end') && i > 0 && lines[i-1].contains('HR -. "Filtra por Tier" .-> HC')) {
      clinicalEndIndex = i;
      break;
    }
  }

  if (clinicalEndIndex != -1) {
    final backendSubGraph = [
      '    subgraph BACKEND["🖥️ Backend - SQLAlchemy (backend.db)"]',
      '        direction TB',
      '        BU["USERS<br/>───────────<br/>id PK<br/>name<br/>email UK<br/>password_hash (bcrypt)<br/>role<br/>is_active<br/>created_at"]',
      '        BUP["USER_PROFILES<br/>───────────<br/>id PK<br/>user_id FK/UK<br/>menstrual_cycle_duration<br/>menstruation_duration<br/>collection_product<br/>contraceptive<br/>age, weight<br/>breast_exam_reminder<br/>privacy_policy_accepted<br/>updated_at"]',
      '        BAL["AUDIT_LOGS<br/>───────────<br/>id PK<br/>user_id FK<br/>action<br/>target_type<br/>target_id<br/>details (JSON)<br/>ip_address<br/>created_at"]',
      '        BAM["ADDITIONAL_MEDICATIONS<br/>───────────<br/>id PK<br/>user_id FK<br/>name<br/>category<br/>updated_at"]',
      '        BDL["DAILY_LOGS<br/>───────────<br/>id PK<br/>user_id FK<br/>date<br/>period_start/end<br/>sexual_intercourse<br/>bleeding_intensity<br/>notes<br/>updated_at"]',
      '',
      '        BU -- "1:1 CASCADE" --> BUP',
      '        BU -- "1:N SET NULL" --> BAL',
      '        BUP -- "1:N" --> BAM',
      '        BUP -- "1:N" --> BDL',
      '    end'
    ];
    
    // Also fix the FRONTEND end bracket (I made it '}' instead of 'end')
    for (int i = 0; i < lines.length; i++) {
        if (lines[i] == '    }') {
            lines[i] = '    end';
        }
    }

    lines.insertAll(clinicalEndIndex + 1, backendSubGraph);
    file.writeAsStringSync(lines.join('\r\n'));
    print('DONE: Restored backend subgraph');
  } else {
    print('Could not find insertion point');
  }
}
