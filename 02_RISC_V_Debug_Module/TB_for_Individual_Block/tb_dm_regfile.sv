`timescale 1ns/1ps

module tb_dm_regfile;

    // ─────────────────────────────────────
    // Signal Declarations
    // ─────────────────────────────────────
    logic        clk;
    logic        rst;
    logic        wen;
    logic [6:0]  addr;
    logic [31:0] wdata;
    logic [31:0] rdata;
    logic        haltreq;
    logic        resumereq;
    logic        dmactive;
    logic        halted      = 1'b0;
    logic        running     = 1'b1;
    logic [31:0] command;
    logic        cmd_valid;
    logic        cmd_busy    = 1'b0;
    logic [2:0]  cmd_err     = 3'b0;
    logic [31:0] data0;
    logic [31:0] data1;
    logic [31:0] data0_rdata = 32'h0;

    // ─────────────────────────────────────
    // Instantiate dm_regfile
    // ─────────────────────────────────────
    dm_regfile dut (
        .clk         (clk),
        .rst         (rst),
        .wen         (wen),
        .addr        (addr),
        .wdata       (wdata),
        .rdata       (rdata),
        .haltreq     (haltreq),
        .resumereq   (resumereq),
        .dmactive    (dmactive),
        .halted      (halted),
        .running     (running),
        .command     (command),
        .cmd_valid   (cmd_valid),
        .cmd_busy    (cmd_busy),
        .cmd_err     (cmd_err),
        .data0       (data0),
        .data1       (data1),
        .data0_rdata (data0_rdata)
    );

    // ─────────────────────────────────────
    // Clock Generation
    // ─────────────────────────────────────
    initial clk = 0;
    always #5 clk = ~clk;

    // ─────────────────────────────────────
    // Tasks
    // ─────────────────────────────────────
    task write_reg(
        input [6:0]  a,
        input [31:0] d
    );
        wen   = 1;
        addr  = a;
        wdata = d;
        #10;
        wen   = 0;
        #10;
    endtask

    task read_reg(
        input  [6:0]  a,
        output [31:0] d
    );
        wen  = 0;
        addr = a;
        #10;
        d = rdata;
    endtask

    // ─────────────────────────────────────
    // Main Test
    // ─────────────────────────────────────
    logic [31:0] read_val;

    initial begin
        rst          = 1;
        wen          = 0;
        addr         = 7'h0;
        wdata        = 32'h0;
        cmd_busy     = 0;
        cmd_err      = 0;
        data0_rdata  = 32'h0;
        halted       = 0;
        running      = 1;

        // ══════════════════════════════════
        // A3: Reset Behaviour
        // ══════════════════════════════════
        $display("─────────────────────────────────");
        $display("A3: Reset Behaviour");
        $display("─────────────────────────────────");

        #30;
        rst = 0;
        $display("Time=%0t: Reset released", $time);

        // Check dmactive=0 after reset
        read_reg(7'h10, read_val);
        if (read_val[0] == 1'b0)
            $display("Time=%0t: PASS: dmactive=0 after reset",
                      $time);
        else
            $display("Time=%0t: FAIL: dmactive not 0 after reset",
                      $time);

        // Write command while dmactive=0
        // Should be IGNORED
        write_reg(7'h17, 32'hDEADBEEF);
        read_reg(7'h17, read_val);
        if (read_val == 32'h0)
            $display("Time=%0t: PASS: command ignored dmactive=0",
                      $time);
        else
            $display("Time=%0t: FAIL: command written dmactive=0 val=0x%h",
                      $time, read_val);

        // Write data0 while dmactive=0
        // Should be IGNORED
        write_reg(7'h04, 32'hCAFEBABE);
        read_reg(7'h04, read_val);
        if (read_val == 32'h0)
            $display("Time=%0t: PASS: data0 ignored dmactive=0",
                      $time);
        else
            $display("Time=%0t: FAIL: data0 written dmactive=0",
                      $time);

        // Write dmcontrol while dmactive=0
        // Should be ACCEPTED
        write_reg(7'h10, 32'h00000001);
        read_reg(7'h10, read_val);
        if (read_val[0] == 1'b1)
            $display("Time=%0t: PASS: dmcontrol writable dmactive=0",
                      $time);
        else
            $display("Time=%0t: FAIL: dmcontrol not writable",
                      $time);

        // ══════════════════════════════════
        // A2: Register Bit Layouts
        // ══════════════════════════════════
        $display("─────────────────────────────────");
        $display("A2: Register Bit Layouts");
        $display("─────────────────────────────────");

        // dmactive=1 now

        // Test haltreq = dmcontrol[31]
        write_reg(7'h10, 32'h80000001);
        #10;
        if (haltreq == 1'b1)
            $display("Time=%0t: PASS: haltreq=dmcontrol[31]=1",
                      $time);
        else
            $display("Time=%0t: FAIL: haltreq not extracted",
                      $time);

        // Test resumereq = dmcontrol[30]
        write_reg(7'h10, 32'h40000001);
        #10;
        if (resumereq == 1'b1)
            $display("Time=%0t: PASS: resumereq=dmcontrol[30]=1",
                      $time);
        else
            $display("Time=%0t: FAIL: resumereq not extracted",
                      $time);

        // Restore dmcontrol
        write_reg(7'h10, 32'h00000001);

        // Test dmstatus — hart halted
        halted  = 1;
        running = 0;
        #10;
        read_reg(7'h11, read_val);
        if (read_val[9]   == 1'b1 &&
            read_val[8]   == 1'b1 &&
            read_val[3:0] == 4'h2)
            $display("Time=%0t: PASS: dmstatus allhalted=1 version=2",
                      $time);
        else
            $display("Time=%0t: FAIL: dmstatus wrong val=0x%h",
                      $time, read_val);

        // Test dmstatus — hart running
        halted  = 0;
        running = 1;
        #10;
        read_reg(7'h11, read_val);
        if (read_val[11] == 1'b1 &&
            read_val[10] == 1'b1 &&
            read_val[9]  == 1'b0)
            $display("Time=%0t: PASS: dmstatus allrunning=1",
                      $time);
        else
            $display("Time=%0t: FAIL: dmstatus running wrong val=0x%h",
                      $time, read_val);

        // Test hartinfo = 0
        read_reg(7'h12, read_val);
        if (read_val == 32'h0)
            $display("Time=%0t: PASS: hartinfo=0",
                      $time);
        else
            $display("Time=%0t: FAIL: hartinfo wrong val=0x%h",
                      $time, read_val);

        // Test command write/read
        write_reg(7'h17, 32'h00231005);
        read_reg(7'h17, read_val);
        if (read_val == 32'h00231005)
            $display("Time=%0t: PASS: command write/read correct",
                      $time);
        else
            $display("Time=%0t: FAIL: command wrong val=0x%h",
                      $time, read_val);

        // Test data0 write/read
        // data0_rdata=0 so no FSM overwrite
        data0_rdata = 32'h0;
        write_reg(7'h04, 32'hDEADBEEF);
        #10;
        read_reg(7'h04, read_val);
        if (read_val == 32'hDEADBEEF)
            $display("Time=%0t: PASS: data0 write/read correct",
                      $time);
        else
            $display("Time=%0t: FAIL: data0 wrong val=0x%h",
                      $time, read_val);

        // Test data1 write/read
        write_reg(7'h05, 32'hCAFEBABE);
        read_reg(7'h05, read_val);
        if (read_val == 32'hCAFEBABE)
            $display("Time=%0t: PASS: data1 write/read correct",
                      $time);
        else
            $display("Time=%0t: FAIL: data1 wrong val=0x%h",
                      $time, read_val);

        // Test abstractcs busy from FSM
        cmd_busy = 1;
        #10;
        read_reg(7'h16, read_val);
        if (read_val[12] == 1'b1)
            $display("Time=%0t: PASS: abstractcs busy=1",
                      $time);
        else
            $display("Time=%0t: FAIL: abstractcs busy wrong",
                      $time);

        cmd_busy = 0;
        #10;
        read_reg(7'h16, read_val);
        if (read_val[12] == 1'b0)
            $display("Time=%0t: PASS: abstractcs busy=0",
                      $time);
        else
            $display("Time=%0t: FAIL: abstractcs busy not cleared",
                      $time);

        // Test abstractcs cmderr from FSM
        cmd_err = 3'd4;
        #10;
        read_reg(7'h16, read_val);
        if (read_val[10:8] == 3'd4)
            $display("Time=%0t: PASS: abstractcs cmderr=4",
                      $time);
        else
            $display("Time=%0t: FAIL: cmderr wrong val=%0d",
                      $time, read_val[10:8]);

        // Test W1C cmderr clear
        write_reg(7'h16, 32'h00000700);
        cmd_err = 3'd0;
        #10;
        read_reg(7'h16, read_val);
        if (read_val[10:8] == 3'b0)
            $display("Time=%0t: PASS: cmderr cleared by W1C",
                      $time);
        else
            $display("Time=%0t: FAIL: cmderr not cleared val=%0d",
                      $time, read_val[10:8]);

        // Test data0 updated from FSM result
        // Simulate FSM completing a read
        cmd_busy    = 1;
        #10;
        cmd_busy    = 0;
        data0_rdata = 32'hDEADBEEF;
        #10;
        read_reg(7'h04, read_val);
        if (read_val == 32'hDEADBEEF)
            $display("Time=%0t: PASS: data0 updated from FSM",
                      $time);
        else
            $display("Time=%0t: FAIL: data0 not from FSM val=0x%h",
                      $time, read_val);

        // Reset data0_rdata
        data0_rdata = 32'h0;

        $display("─────────────────────────────────");
        $display("Time=%0t: All tests done", $time);
        $finish;
    end

endmodule