`timescale 1ns/1ps

module tb_dmi_slave;

    logic        clk;
    logic        rst;
    logic [1:0]  dmi_op;
    logic [6:0]  dmi_addr;
    logic [31:0] dmi_wdata;
    logic [1:0]  dmi_resp  = 2'b00;
    logic [31:0] dmi_rdata = 32'h0;
    logic        reg_wen   = 1'b0;
    logic [6:0]  reg_addr  = 7'h0;
    logic [31:0] reg_wdata = 32'h0;
    logic [31:0] reg_rdata;
    logic        dmactive  = 1'b0;

    dmi_slave dut (
        .clk      (clk),
        .rst      (rst),
        .dmi_op   (dmi_op),
        .dmi_addr (dmi_addr),
        .dmi_wdata(dmi_wdata),
        .dmi_resp (dmi_resp),
        .dmi_rdata(dmi_rdata),
        .reg_wen  (reg_wen),
        .reg_addr (reg_addr),
        .reg_wdata(reg_wdata),
        .reg_rdata(reg_rdata)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // Mini register file
    logic [31:0] regfile_mem [0:127];
    integer idx;
    initial begin
        for (idx = 0; idx < 128; idx = idx + 1)
            regfile_mem[idx] = 32'h0;
    end
    always_ff @(posedge clk) begin
        if (reg_wen)
            regfile_mem[reg_addr] <= reg_wdata;
    end
    assign reg_rdata = regfile_mem[dmi_addr];

    // Track dmactive
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            dmactive <= 1'b0;
        else if (reg_wen && reg_addr == 7'h10)
            dmactive <= reg_wdata[0];
    end

    initial begin
        rst      = 1;
        dmi_op   = 2'b00;
        dmi_addr = 7'h0;
        dmi_wdata= 32'h0;

        // ══════════════════════════════════
        // WAVEFORM 2: dmactive Reset Release
        // ══════════════════════════════════
        $display("─────────────────────────────────");
        $display("WAVEFORM 2: dmactive Reset Release");
        $display("─────────────────────────────────");

        #30;
        rst = 0;
        $display("Time=%0t: rst released", $time);

        // Write dmactive=1
        #10;
        dmi_op   = 2'b10;
        dmi_addr = 7'h10;
        dmi_wdata= 32'h00000001;
        #10;
        dmi_op   = 2'b00;
        $display("Time=%0t: dmactive=1 written", $time);

        // Read back dmcontrol
        #10;
        dmi_op   = 2'b01;
        dmi_addr = 7'h10;
        #10;
        dmi_op   = 2'b00;
        if (dmi_rdata[0] == 1'b1)
            $display("Time=%0t: PASS: dmactive=1 confirmed",
                      $time);
        else
            $display("Time=%0t: FAIL: dmactive not set dmi_rdata=0x%h",
                      $time, dmi_rdata);

        // ══════════════════════════════════
        // WAVEFORM 1: DMI Transactions
        // ══════════════════════════════════
        $display("─────────────────────────────────");
        $display("WAVEFORM 1: DMI Transactions");
        $display("─────────────────────────────────");

        // Transaction 1: WRITE
        #10;
        dmi_op   = 2'b10;
        dmi_addr = 7'h17;
        dmi_wdata= 32'hDEADBEEF;
        #10;
        dmi_op   = 2'b00;
        $display("Time=%0t: WRITE addr=0x17 data=0xDEADBEEF",
                  $time);
        if (reg_wen  == 1'b1         &&
            reg_addr == 7'h17        &&
            reg_wdata== 32'hDEADBEEF &&
            dmi_resp == 2'b00)
            $display("Time=%0t: PASS: WRITE correct",
                      $time);
        else
            $display("Time=%0t: FAIL: WRITE failed reg_wen=%b addr=%h wdata=%h",
                      $time, reg_wen, reg_addr, reg_wdata);

        // Transaction 2: READ
        #10;
        dmi_op   = 2'b01;
        dmi_addr = 7'h17;
        #10;
        dmi_op   = 2'b00;
        $display("Time=%0t: READ addr=0x17 data=0x%h",
                  $time, dmi_rdata);
        if (dmi_rdata == 32'hDEADBEEF &&
            reg_wen   == 1'b0         &&
            dmi_resp  == 2'b00)
            $display("Time=%0t: PASS: READ correct",
                      $time);
        else
            $display("Time=%0t: FAIL: READ failed dmi_rdata=0x%h",
                      $time, dmi_rdata);

        // Transaction 3: READ-AFTER-WRITE
        #10;
        $display("Time=%0t: Starting READ-AFTER-WRITE",
                  $time);
        dmi_op   = 2'b10;
        dmi_addr = 7'h17;
        dmi_wdata= 32'hCAFEBABE;
        #10;
        dmi_op   = 2'b01;
        dmi_addr = 7'h17;
        dmi_wdata= 32'h0;
        #10;
        dmi_op   = 2'b00;
        $display("Time=%0t: READ-AFTER-WRITE data=0x%h",
                  $time, dmi_rdata);
        if (dmi_rdata == 32'hCAFEBABE &&
            dmi_resp  == 2'b00)
            $display("Time=%0t: PASS: READ-AFTER-WRITE correct",
                      $time);
        else
            $display("Time=%0t: FAIL: READ-AFTER-WRITE failed 0x%h",
                      $time, dmi_rdata);

        $display("─────────────────────────────────");
        $display("Time=%0t: All tests done", $time);
        $finish;
    end

endmodule