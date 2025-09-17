<?php
$filename_json='jelentkezesek.json';
if(!file_exists($filename_json)) file_put_contents($filename_json,json_encode([]));
$data=json_decode(file_get_contents($filename_json),true);

// Ellenőrizzük a role paramétert
$role = $_GET['role'] ?? '';
if(!in_array($role,['Diák','Tanár'])) die('Hibás szerepkör!');

// Szűrjük az adatokat
$filtered = array_filter($data, fn($e) => ($e['role'] ?? '') === $role);

// Csoportosítás név szerint
$grouped = [];
foreach($filtered as $entry){
    $name = $entry['name'] ?? '';
    if(!isset($grouped[$name])) $grouped[$name] = [];
    $grouped[$name][] = $entry['date'] ?? '';
}

// CSV generálás memóriába
header('Content-Type: text/csv; charset=UTF-8');
header('Content-Disposition: attachment; filename="'.($role=='Diák'?'diak':'tanar').'_jelentkezesek.csv"');

$output = fopen('php://output', 'w');
fprintf($output, chr(0xEF).chr(0xBB).chr(0xBF)); // BOM UTF-8
fputcsv($output, ['Név','Napok'], ';');

foreach($grouped as $name=>$dates){
    fputcsv($output, [$name, implode(', ', $dates)], ';');
}

fclose($output);
exit;
?>