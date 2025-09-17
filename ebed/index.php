<?php
session_start();

// JSON fájl
$filename = 'jelentkezesek.json';
if (!file_exists($filename)) file_put_contents($filename, json_encode([]));
$data = json_decode(file_get_contents($filename), true);

// Magyar hónapok
$months_hu = [1=>'január',2=>'február',3=>'március',4=>'április',5=>'május',6=>'június',7=>'július',8=>'augusztus',9=>'szeptember',10=>'október',11=>'november',12=>'december'];

// Aktuális hónap + 2 hét minden hétköznapja (hétfőtől péntekig)
$monthDates = [];
$today = new DateTime();
$today->setTime(0,0,0); // idő nullázása

$year = (int)$today->format('Y');
$month = (int)$today->format('n');

// Kezdés: hónap első napja
$start = new DateTime("$year-$month-01");
// Vége: hónap utolsó napja + 2 hét
$end = clone $start;
$end->modify('last day of this month');
$end->modify('+14 days');

while ($start <= $end) {
    $dayOfWeek = (int)$start->format('N'); // 1=hétfő, 7=vasárnap
    // Csak hétfő-péntek és a mai nap vagy későbbi
    if ($dayOfWeek <= 5 && $start >= $today) {
        $day = (int)$start->format('j');
        $monthNum = (int)$start->format('n');
        $yearNum = $start->format('Y');
        $monthDates[] = $yearNum.'. '.$months_hu[$monthNum].' '.$day.'.';
    }
    $start->modify('+1 day');
}


// Csoportosítás név szerint a toggle-hoz
$groupedData = [];
foreach ($data as $entry) {
    $name = $entry['name'] ?? '';
    if (!isset($groupedData[$name])) $groupedData[$name] = [];
    $groupedData[$name][] = $entry['date'] ?? '';
}
?>

<!DOCTYPE html>
<html lang="hu">
<head>
<meta charset="UTF-8">
<title>Ebéd jelentkezés</title>
<style>
body{font-family:Arial,sans-serif;background:#f0f2f5;margin:0;padding:0;}
.container{max-width:700px;margin:40px auto;background:#fff;padding:30px;border-radius:12px;box-shadow:0 4px 15px rgba(0,0,0,0.1);}
h1{text-align:center;color:#333;margin-bottom:25px;}
form{display:flex;flex-direction:column;gap:15px;}
input,select,button{padding:10px;font-size:1rem;border-radius:6px;border:1px solid #ccc;}
select[multiple]{height:120px;}
button{background:#4CAF50;color:white;border:none;cursor:pointer;transition:0.3s;}
button:hover{background:#45a049;}
label{font-weight:600;color:#555;}
.entries{margin-top:30px;}
.entry{background:#f9f9f9;padding:15px;border-radius:8px;margin-bottom:10px;display:flex;flex-direction:column;}
.toggle-header{cursor:pointer;font-weight:600;margin-bottom:5px;}
.toggle-header:hover{color:#2196F3;}
.toggle-content{display:none;margin-top:5px;}
.warning{background:#ffdddd;color:#a00;padding:10px;border-radius:6px;margin-bottom:15px;}
.export-btn{background:#2196F3;margin-top:10px;}
</style>
</head>
<body>
<div class="container">
<h1>Ebéd jelentkezés</h1>

<?php if(!empty($_SESSION['warning'])): ?>
<div class="warning"><?php echo $_SESSION['warning']; unset($_SESSION['warning']); ?></div>
<?php endif; ?>

<form action="save.php" method="post">
<label>Tanár/Diák neve:</label>
<input type="text" name="name" required placeholder="Teljes név">

<label>Jelentkező típusa:</label>
<select name="role" required>
  <option value="" disabled selected>Válasszon!</option>
  <option value="Diák">Diák</option>
  <option value="Tanár">Tanár</option>
</select>

<label>Dátum(ok) kiválasztása:</label>
<select name="date[]" multiple required>
<?php foreach($monthDates as $date): ?>
<option value="<?php echo htmlspecialchars($date, ENT_QUOTES, 'UTF-8'); ?>">
    <?php echo htmlspecialchars($date, ENT_QUOTES, 'UTF-8'); ?>
</option>
<?php endforeach; ?>
</select>

<button type="submit">Jelentkezés</button>
</form>

<form action="export.php" method="get">
  <button type="submit" name="role" value="Diák" class="export-btn">Diákok exportálása</button>
  <button type="submit" name="role" value="Tanár" class="export-btn">Tanárok exportálása</button>
</form>


<div class="entries">
<h2>Jelentkezett Diákok</h2>
<?php
$students = array_filter($data, fn($e) => ($e['role'] ?? '') === 'Diák');
$groupedStudents = [];
foreach($students as $entry){
    $name = $entry['name'] ?? '';
    if(!isset($groupedStudents[$name])) $groupedStudents[$name] = [];
    $groupedStudents[$name][] = $entry['date'] ?? '';
}
?>
<?php foreach($groupedStudents as $name => $dates): ?>
<div class="entry">
<?php
$firstEntry=null;
foreach($students as $entry){ if(($entry['name'] ?? '') === $name){ $firstEntry=$entry; break; } }
$timeText='';
if($firstEntry){
    $timeText = ($firstEntry['date'] ?? '').' '.($firstEntry['time'] ?? '').' – '.($firstEntry['role'] ?? '');
}
?>

<p><?php echo htmlspecialchars($name,ENT_QUOTES,'UTF-8'); ?> jelentkezett</p>

<span class="toggle-header">&#9654; Részletek</span>
<div class="toggle-content">
<p>Dátumok: <?php echo implode(', ',$dates); ?></p>
</div>
</div>
<?php endforeach; ?>

<h2>Jelentkezett Tanárok</h2>
<?php
$teachers = array_filter($data, fn($e) => ($e['role'] ?? '') === 'Tanár');
$groupedTeachers = [];
foreach($teachers as $entry){
    $name = $entry['name'] ?? '';
    if(!isset($groupedTeachers[$name])) $groupedTeachers[$name] = [];
    $groupedTeachers[$name][] = $entry['date'] ?? '';
}
?>
<?php foreach($groupedTeachers as $name => $dates): ?>
<div class="entry">
<?php
$firstEntry=null;
foreach($teachers as $entry){ if(($entry['name'] ?? '') === $name){ $firstEntry=$entry; break; } }
$timeText='';
if($firstEntry){
    $timeText = ($firstEntry['date'] ?? '').' '.($firstEntry['time'] ?? '').' – '.($firstEntry['role'] ?? '');
}
?>
<p><?php echo htmlspecialchars($name,ENT_QUOTES,'UTF-8'); ?> jelentkezett</p>

<span class="toggle-header">&#9654; Részletek</span>
<div class="toggle-content">
<p>Dátumok: <?php echo implode(', ',$dates); ?></p>
</div>
</div>
<?php endforeach; ?>
</div>

<script>
document.querySelectorAll('.toggle-header').forEach(header=>{
header.addEventListener('click',function(){
this.nextElementSibling.style.display=(this.nextElementSibling.style.display==='block')?'none':'block';
});
});
document.addEventListener("DOMContentLoaded",function(){
const select=document.querySelector("select[name='date[]']");
for(let option of select.options){option.addEventListener('mousedown',function(e){e.preventDefault();this.selected=!this.selected;});}
});
</script>
</body>
</html>
