`timescale 1ns/1ps

module tb_rca_16bit;
	reg [15:0]a;
	reg [15:0]b;
	reg cin;
	wire [15:0]sum;
	wire cout;
	
	reg [16:0]expected;
	integer pass_count;
	integer fail_count;
	integer test_num;
	
	time start_time; //for Delay calculation
	time end_time;
	time prop_delay;
	time worst_delay;


	//DUT
	
	rca_16bit dut(
		.a(a),
		.b(b),
		.cin(cin),
		.sum(sum),
		.cout(cout));

	//task for one directed/random test
	task run_test;
	
	//golden model using +
	begin
	expected = a+b+cin;

	start_time=$realtime;
	#1; //wait for combinational propagation
	end_time=$realtime;
	prop_delay=end_time-start_time;
	
		if(prop_delay>worst_delay)
		worst_delay=prop_delay;

		if({cout,sum}==expected)begin
		$display("TEST %0d PASS: A=%h B=%h Cin=%b => sum=%h  cout=%b",test_num,a,b,cin,sum,cout);
		pass_count=pass_count+1;			
		end

		else begin
		$display("TEST %0d FAIL: A=%h B=%h Cin=%b => sum=%h  cout=%b expecsum=%h		expeccout=%b",test_num,a,b,cin,sum,cout,expected[15:0],expected[16]);
		fail_count=fail_count+1;	
		end
	end
	endtask

initial begin
$display("======================================================");
$display("       16-bit Ripple Carry Adder Testing              ");
$display("======================================================");

pass_count=0;
fail_count=0;
worst_delay=0;


//directed test vector
a=16'h0000;b=16'h0000;cin=1'b0;test_num=1;run_test;
a=16'hFFFF;b=16'h0001;cin=1'b0;test_num=2;run_test;
a=16'hAAAA;b=16'h5555;cin=1'b0;test_num=3;run_test;
a=16'h00FF;b=16'h0001;cin=1'b0;test_num=4;run_test;
a=16'h1234;b=16'h5678;cin=1'b0;test_num=5;run_test;
a=16'hFFFF;b=16'hFFFF;cin=1'b1;test_num=6;run_test;
a=16'h8000;b=16'h8000;cin=1'b0;test_num=7;run_test;
a=16'h0F0F;b=16'hF0F0;cin=1'b0;test_num=8;run_test;

//directed test_summary
$display("-------------------------------------------------------");
$display("Directed test_summary: pass=%0d , fail=%0d", pass_count,fail_count);
$display("-------------------------------------------------------");

//100 random tests

repeat(100)begin		
a=$random;
b=$random;
cin=$random;
test_num=test_num+1;
run_test;
end

$display("-------------------------------------------------------");
$display("Final test_summary: pass=%0d , fail=%0d", pass_count,fail_count);
$display("worst_delay=%0t",worst_delay);
$display("worst_case carry ripple stages=16");
$display("worst_case theoretical delay=16*t_carry");
$display("-------------------------------------------------------");
$finish;
end
endmodule
																																																																																																																																																																																																																																																																																																																																																																																									



	
