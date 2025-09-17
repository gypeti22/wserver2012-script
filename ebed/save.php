<?php
$filename='jelentkezesek.json';
if(!file_exists($filename)) file_put_contents($filename,json_encode([]));
$data=json_decode(file_get_contents($filename),true);

$name=trim($_POST['name'] ?? '');
$role=$_POST['role'] ?? '';
$dates=$_POST['date'] ?? [];

if($name && $role && !empty($dates)){
    foreach($dates as $d){
        $data[]=[
            'name'=>$name,
            'date'=>$d,
            'time'=>date('H:i'),
            'role'=>$role
        ];
    }
    file_put_contents($filename,json_encode($data,JSON_PRETTY_PRINT|JSON_UNESCAPED_UNICODE));
}

header("Location:index.php");
exit;
?>
