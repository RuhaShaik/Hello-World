<!DOCTYPE html>
<html>
<head>
	<title>Assignment 2 </title>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1"> 
	<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css">
</head>
<body>
	<div class="container-fluid" style="padding:0">
		<div class="row" >
			<div class="col-lg-12 col-md-12 col-sm-12 col-xs-12">
				<img src="emp.jpg">
			</div>
		</div>	
		<?php
					$conn=mysqli_connect("localhost","root","","ruha");
					if(!$conn){
					die("connection faild: ". mysqli_connect_error);
					}
					else
					{
						$sql = "SELECT * FROM emp_details";
					}
		?>
		<div class="row " style="padding:50px 150px 0 150px;">
			<div class="col-lg-12 col-md-12 col-sm-12 col-xs-12 text-center">
				<form action="" method="POST">
					<select name = "experience" style="height:30px; width:250px;">
						<option disabled selected>Select Experience</option>
						<?php								
							$result = mysqli_query($conn, 'SELECT DISTINCT ServiceOfEmployee FROM emp_details');
							if (mysqli_num_rows($result) > 0) {						
							while($row = mysqli_fetch_assoc($result)) {	
								echo '<option value="'.$row["ServiceOfEmployee"].'">'.$row["ServiceOfEmployee"].'</option>';										
								}								
							}
						?> 
					</select>
					<select name="branch" style="height:30px; width:250px;">
						<option disabled selected>Select Branch</option>
						<?php							
							$result = mysqli_query($conn, 'SELECT DISTINCT Specialization FROM emp_details');
							if (mysqli_num_rows($result) > 0) {						
							while($row = mysqli_fetch_assoc($result)) {	
								echo '<option value="'.$row["Specialization"].'">'.$row["Specialization"].'</option>';										
								}								
							}
						?>
					</select>
					<select name="designation" style="height:30px; width:250px;">
						<option disabled selected>Select Designation</option>
						<?php						
							$result = mysqli_query($conn, 'SELECT DISTINCT Designation FROM emp_details');
							if (mysqli_num_rows($result) > 0) {						
							while($row = mysqli_fetch_assoc($result)) {	
								echo '<option value="'.$row["Designation"].'">'.$row["Designation"].'</option>';										
								}								
							}
						?>
					</select>
					<br><br>
					<input type="submit" name="submit" class="btn btn-info" value="Get Details" style="width:250px;">
					<br><br>
					
				</form>				
				<?php					
					if(isset($_POST['submit']) ){
						if(isset($_POST['experience'])){
							if(isset($_POST['branch'])){
								if(isset($_POST['designation'])){
									$a=$_POST['experience'];	
									$b=$_POST['branch'];	
									$c=$_POST['designation'];
									$sql = "SELECT * FROM emp_details where ServiceOfEmployee='".$a."' and Specialization='".$b."'and Designation='".$c."';";
								}
								else{
									$a=$_POST['experience'];	
									$b=$_POST['branch'];	
									$sql = "SELECT * FROM emp_details where ServiceOfEmployee='".$a."' and Specialization='".$b."';";
								}
							}
							else if(isset($_POST['designation'])){
								$a=$_POST['experience'];	
								$c=$_POST['designation'];
								$sql = "SELECT * FROM emp_details where ServiceOfEmployee='".$a."' and Designation='".$c."';";
							}
							else{
								$a=$_POST['experience'];	
								$sql = "SELECT * FROM emp_details where ServiceOfEmployee='".$a."';";
							}	
						}
						else if(isset($_POST['branch'])){
							if(isset($_POST['designation'])){
								$b=$_POST['branch'];	
								$c=$_POST['designation'];
								$sql = "SELECT * FROM emp_details where Designation='".$c."' and Specialization='".$b."';";
							}
							else{
								$b=$_POST['branch'];
								$sql = "SELECT * FROM emp_details where Specialization='".$b."';";
							}
						}
						else if(isset($_POST['branch'])){
							$c=$_POST['designation'];
							$sql = "SELECT * FROM emp_details where Designation ='".$c."';";
						}
						else{
							echo "enter data";
						}
						$result = $conn->query($sql);
						if ($result->num_rows > 0) {
						echo '<table class="table table-bordered">
						<thead style="background-color:rgb(112,173,71)">
							<tr style="color:white">';
							echo "<th>Dept</th>
								<th>Emp ID</th>
								<th>General Name</th>
								<th>Specialization</th>
								<th>Service of Employee</th>
								<th>E-Mail ID</th>
								<th>Designation</th>
							</tr>
						</thead>";
						echo "<tbody>";
						$ct=0;
						while($row = $result->fetch_assoc()){
							
								echo " <tr>
								<td>" . $row["Dept"]. "</td>
								<td>" . $row["EmpID"]. "</td>
								<td>" . $row["GeneralName"]. "</td>
								<td>" . $row["Specialization"]. "</td>
								<td>" . $row["ServiceOfEmployee"]. "</td>
								<td>" . $row["E-MailID"].  "</td>
								<td>" . $row["Designation"].  "</td>
								</tr>";
								$ct++;
														
						}
						if($ct==0){
							echo "<h3>There is no data to Display</h3>";
						}
						echo "</table>";
						}
						else {
							echo "0 results";
						}
						}
												
										
						/* if(isset($_POST['experience'])&&isset($_POST['branch'])&&isset($_POST['designation'])){
						$sel=$_POST['experience'];	
						$sel1=$_POST['branch'];	
						$sel2=$_POST['designation'];											
						$result = $conn->query($sql);
						if ($result->num_rows > 0) {
						echo '<table class="table table-bordered">
						<thead style="background-color:rgb(112,173,71)">
							<tr style="color:white">';
							echo "<th>Dept</th>
								<th>Emp ID</th>
								<th>General Name</th>
								<th>Specialization</th>
								<th>Service of Employee</th>
								<th>E-Mail ID</th>
								<th>Designation</th>
							</tr>
						</thead>";
						echo "<tbody>";
						$ct=0;
						while($row = $result->fetch_assoc()){
							if(($sel==$row["ServiceOfEmployee"])&&($sel1==$row["Specialization"])&&($sel2==$row["Designation"])){
								echo " <tr>
								<td>" . $row["Dept"]. "</td>
								<td>" . $row["EmpID"]. "</td>
								<td>" . $row["GeneralName"]. "</td>
								<td>" . $row["Specialization"]. "</td>
								<td>" . $row["ServiceOfEmployee"]. "</td>
								<td>" . $row["E-MailID"].  "</td>
								<td>" . $row["Designation"].  "</td>
								</tr>";
								$ct++;
							}							
						}
						if($ct==0){
							echo "<h3>There is no data to Display</h3>";
						}
						echo "</table>";
						}
						else {
							echo "0 results";
						}
						}
						else{
							if(($sel=($_POST['experience']) && $sel1=($_POST['branch'])) || ($sel1=($_POST['branch']) && $sel2=($_POST['designation'])) || ($sel=($_POST['experience']) && $sel2=($_POST['designation']) )){
								
							}
							else if($sle=($_POST['experience'])||$sel1=($_POST['branch'])||$sel2=($_POST['designation'])){
								
							}
						} */
					}				
					$conn->close();					
				?>
			</div>
		</div>
	</div>
</body>
</html>