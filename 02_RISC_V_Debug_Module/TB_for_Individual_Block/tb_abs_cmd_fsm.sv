module tb_abstract_cmd_fsm;

    logic clk, rst_n;

    // DUT signals
    logic cmd_valid;
    logic [31:0] command_reg;
    logic [31:0] data0_in;

    logic hart_halted;
    logic hart_resp_valid;
    logic [31:0] hart_resp_rdata;

    logic hart_req_valid;
    logic hart_req_write;
    logic [15:0] hart_req_addr;
    logic [31:0] hart_req_wdata;

    logic [31:0] data0_out;
    logic busy;
    logic [2:0] cmderr;
    logic [1:0] delay;

    // Instantiate DUT
    abstract_cmd_fsm dut (.*);

    // Clock
    always #5 clk = ~clk;

    // -----------------------------
    // Simple hart model
    // -----------------------------
    always_ff @(posedge clk) begin
        hart_resp_valid <= 0;

        if (hart_req_valid) begin
            delay<= 2;
        end

        if (delay!=0)begin
            delay<=delay-1;
        end
            if (delay==1) begin
                hart_resp_valid<=1;
                hart_resp_rdata<=32'hDEADBEEF;
            end

    end

    // -----------------------------
    // Test sequence
    // -----------------------------
    initial begin
        clk = 0;
        rst_n = 0;
        cmd_valid = 0;
        hart_halted = 0;
        data0_in = 32'h12345678;

        #20;
        rst_n = 1;

        // ----------------------------------
        // TEST 1: ERROR (hart running)
        // ----------------------------------
        $display("TEST 1: Error case (hart running)");
        command_reg = 32'd0;
        command_reg[22:20] = 3'b010;  // aarsize = 32-bit
        command_reg[17]    = 1'b1;    // transfer = 1
        command_reg[16]    = 1'b0;    // write = 0 (READ)
        command_reg[15:0]  = 16'h1005; // regno (GPR x5)
        
        cmd_valid = 1;
        #10;
        cmd_valid = 0;

        wait(busy==0);
        #10;
        $display("cmderr = %0d (expect 4)", cmderr);

        // ----------------------------------
        // TEST 2: SUCCESSFUL GPR READ
        // ----------------------------------
        $display("TEST 2: GPR READ");
        hart_halted = 1;

        command_reg = 32'd0;
        command_reg[22:20] = 3'b010;
        command_reg[17]    = 1'b1;
        command_reg[16]    = 1'b0;
        command_reg[15:0]  = 16'h1005;
        
        cmd_valid = 1;
        #10;
        cmd_valid = 0;

        wait (busy == 0);
        #10;
        $display("data0_out = %h", data0_out);

        // ----------------------------------
        // TEST 3: CSR WRITE
        // ----------------------------------
        $display("TEST 3: CSR WRITE");

        data0_in = 32'hA5A5A5A5;

        command_reg = 32'd0;

        command_reg[22:20] = 3'b010;
        command_reg[17]    = 1'b1;
        command_reg[16]    = 1'b1;    // WRITE
        command_reg[15:0]  = 16'h0305; // mtvec CSR// mtvec
        cmd_valid = 1;
        #10;
        cmd_valid = 0;

        wait (busy == 0);
        #20;

        $display("Write completed");

        $finish;
    end
endmodule