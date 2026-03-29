`timescale 1ns/1ps
module tb_csa_16bit;
	
	reg [15:0]a,b;
	reg cin;
	wire [15:0]sum;
	wire cout;	
	wire [3:0]p_blocks;

	reg [16:0]expected;
	integer pass_count,fail_count;
	integer i;
	integer test_num;

//DUT

csa_16bit dut(.a(a),	
	      .b(b),
	      .cin(cin),
	      .sum(sum),	
	      .cout(cout),
	      .p_block(p_blocks));

task run_test;

	begin	
	//golden model using +
	
	expected = a+b+cin;
	#1;
	
		if({cout,sum}==expected)begin
		$display("TEST %0d PASS: A=%h B=%h Cin=%b =>  sum=%h  cout=%b p_blocks=%b" , test_num,a,b,cin,sum,cout,p_blocks);
		pass_count=pass_count+1;
		end

		else begin
		$display("TEST %0d FAIL: A=%h B=%h Cin=%b => sum=%h  cout=%b expecsum=%h		expeccout=%b",test_num,a,b,cin,sum,cout,expected[15:0],expected[16],p_blocks);
		fail_count=fail_count+1;	
		end
		$display("skip status per block [3:0]=%b",p_blocks);
		end
		endtask

initial begin
$display("======================================================");
$display("         16-bit Carry skip Adder Testing              ");
$display("======================================================");

pass_count=0;
fail_count=0;

//directed test vector
a=16'h0000;b=16'h0000;cin=1'b0;test_num=1;run_test;
a=16'hFFFF;b=16'h0001;cin=1'b0;test_num=2;run_test;
a=16'hAAAA;b=16'h5555;cin=1'b0;test_num=3;run_test;
a=16'h00FF;b=16'h0001;cin=1'b0;test_num=4;run_test;
a=16'h1234;b=16'h5678;cin=1'b0;test_num=5;run_test;
a=16'hFFFF;b=16'hFFFF;cin=1'b1;test_num=6;run_test;
a=16'h8000;b=16'h8000;cin=1'b0;test_num=7;run_test;
a=16'h0F0F;b=16'hF0F0;cin=1'b0;test_num=8;run_test;

//Extra tests

a=16'h5555;b=16'h2222;cin=1'b0;test_num=9;run_test;
a=16'hFFFF;b=16'h0001;cin=1'b0;test_num=10;run_test;
a=16'h3333;b=16'h4444;cin=1'b0;test_num=11;run_test;
a=16'hFFFF;b=16'hFFFF;cin=1'b0;test_num=12;run_test;

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

$display("---------------------------------------------");
$display("Final test_summary: pass=%0d , fail=%0d", pass_count,fail_count);
$display("---------------------------------------------");
$finish;

end
endmodule
