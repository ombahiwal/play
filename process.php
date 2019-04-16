<?php

$conn = mysqli_connect("mysql-master-dbserver.cnvdbyqk1leu.us-east-1.rds.amazonaws.com","omkarbahiwal","Omkar109","masterdb");
$sql = "select * from demotable";
$result = $conn->query($sql);
var_dump(mysqli_fetch_assoc($result));


if(isset($_POST['data'])){
    $add = $_POST['one'] + $_POST['two'];
    
echo "Addition is {$add}";
    
}


//header("location:http://18.235.204.3/aws/index.html?igotit=0".$_POST['data']);
?>

