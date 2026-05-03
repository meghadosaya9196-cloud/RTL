`timescale 1ns/1ps

module tb_hart_stub;

    // ─────────────────────────────────────
    // Signal Declarations
    // ─────────────────────────────────────
    logic        clk;
    logic        rst;
    logic        halt_req;
    logic        resume_req;
    logic        halted;
    logic        running;
    logic        reg_req;
    logic        reg_write;
    logic [15:0] regno;
    logic [31:0] write_data;
    logic        reg_ack;
    logic [31:0] read_data;

    // ─────────────────────────────────────
    // Instantiate hart_stub
    // ─────────────────────────────────────
    hart_stub dut (
        .clk        (clk),
        .rst        (rst),
        .halt_req   (halt_req),
        .resume_req (resume_req),
        .halted     (halted),
        .running    (running),
        .reg_req    (reg_req),
        .reg_write  (reg_write),
        .regno      (regno),
        .write_data (write_data),
        .reg_ack    (reg_ack),
        .read_data  (read_data)
    );

    // ─────────────────────────────────────
    // Clock Generation
    // ─────────────────────────────────────
    initial clk = 0;
    always #5 clk = ~clk;  // 10ns period = 100MHz

    // ─────────────────────────────────────
    // Main Test
    // ─────────────────────────────────────
    initial begin
        // Initialize all signals
        rst        = 1;
        halt_req   = 0;
        resume_req = 0;
        reg_req    = 0;
        reg_write  = 0;
        regno      = 0;
        write_data = 0;

        // Hold reset for 20ns (2 clock cycles)
        #20;
        rst = 0;
        $display("Time=%0t: Reset released", $time);

        // ── Test 1: Halt ──────────────────
        #10;
        halt_req = 1;
        #10;
        halt_req = 0;
        #10;
        if (halted == 1)
            $display("Time=%0t: PASS: Hart halted",
                      $time);
        else
            $display("Time=%0t: FAIL: Hart did not halt",
                      $time);

        // ── Test 2: Write x5 = 0xDEADBEEF ─
        #10;
        reg_req    = 1;
        reg_write  = 1;
        regno      = 16'h1005;
        write_data = 32'hDEADBEEF;
        wait(reg_ack == 1);
        #1;
        reg_req    = 0;
        reg_write  = 0;
        $display("Time=%0t: Write x5 = 0xDEADBEEF done",
                  $time);

        // ── Test 3: Read x5 back ──────────
        #10;
        reg_req   = 1;
        reg_write = 0;
        regno     = 16'h1005;
        wait(reg_ack == 1);
        #1;
        reg_req = 0;
        #10;
        if (read_data == 32'hDEADBEEF)
            $display("Time=%0t: PASS: x5 = 0x%h",
                      $time, read_data);
        else
            $display("Time=%0t: FAIL: x5 = 0x%h expected 0xDEADBEEF",
                      $time, read_data);

        // ── Test 4: Write mtvec CSR ───────
        #10;
        reg_req    = 1;
        reg_write  = 1;
        regno      = 16'h0305;
        write_data = 32'hCAFEBABE;
        wait(reg_ack == 1);
        #1;
        reg_req    = 0;
        reg_write  = 0;
        $display("Time=%0t: Write mtvec done", $time);

        // ── Test 5: Read mtvec back ───────
        #10;
        reg_req   = 1;
        reg_write = 0;
        regno     = 16'h0305;
        wait(reg_ack == 1);
        #1;
        reg_req = 0;
        #10;
        if (read_data == 32'hCAFEBABE)
            $display("Time=%0t: PASS: mtvec = 0x%h",
                      $time, read_data);
        else
            $display("Time=%0t: FAIL: mtvec = 0x%h expected 0xCAFEBABE",
                      $time, read_data);

        // ── Test 6: Resume ────────────────
        #10;
        resume_req = 1;
        #10;
        resume_req = 0;
        #10;
        if (halted == 0)
            $display("Time=%0t: PASS: Hart resumed",
                      $time);
        else
            $display("Time=%0t: FAIL: Hart did not resume",
                      $time);

        $display("Time=%0t: All tests done", $time);
        $finish;
    end

endmodule