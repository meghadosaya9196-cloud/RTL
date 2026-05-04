`timescale 1ns/1ps

module tb_halt_resume_ctrl;

    // ─────────────────────────────────────
    // Signal Declarations
    // ─────────────────────────────────────
    logic clk;
    logic rst;
    logic dmactive   = 1'b0;
    logic haltreq    = 1'b0;
    logic resumereq  = 1'b0;
    logic halt;
    logic resume;
    logic halted     = 1'b0;
    logic running    = 1'b1;
    logic allhalted;
    logic allrunning;

    // ─────────────────────────────────────
    // Instantiate
    // ─────────────────────────────────────
    halt_resume_ctrl dut (
        .clk      (clk),
        .rst      (rst),
        .dmactive (dmactive),
        .haltreq  (haltreq),
        .resumereq(resumereq),
        .halt     (halt),
        .resume   (resume),
        .halted   (halted),
        .running  (running),
        .allhalted(allhalted),
        .allrunning(allrunning)
    );

    // ─────────────────────────────────────
    // Clock
    // ─────────────────────────────────────
    initial clk = 0;
    always #5 clk = ~clk;

    // ─────────────────────────────────────
    // Main Test
    // ─────────────────────────────────────
    initial begin
        rst      = 1;
        dmactive = 0;
        haltreq  = 0;
        resumereq= 0;
        halted   = 0;
        running  = 1;

        #30;
        rst      = 0;
        dmactive = 1;
        $display("─────────────────────────────────");
        $display("Time=%0t: Reset released dmactive=1",
                  $time);

        // ══════════════════════════════════
        // C1: haltreq → halt → halted → allhalted
        // ══════════════════════════════════
        $display("─────────────────────────────────");
        $display("C1: haltreq → halt → halted → allhalted");
        $display("─────────────────────────────────");

        // Assert haltreq
        #10;
        haltreq = 1;
        #10;
        haltreq = 0;

        // Check halt asserted
        #10;
        if (halt == 1)
            $display("Time=%0t: PASS: halt=1 asserted to hart",
                      $time);
        else
            $display("Time=%0t: FAIL: halt not asserted",
                      $time);

        // Check allhalted NOT yet set
        // (hart hasn't confirmed yet)
        if (allhalted == 0)
            $display("Time=%0t: PASS: allhalted=0 waiting for hart",
                      $time);
        else
            $display("Time=%0t: FAIL: allhalted set too early",
                      $time);

        // Simulate hart confirming halt
        #10;
        halted  = 1;
        running = 0;
        #10;

        // NOW allhalted should be 1
        if (allhalted == 1)
            $display("Time=%0t: PASS: allhalted=1 after hart confirmed",
                      $time);
        else
            $display("Time=%0t: FAIL: allhalted not set",
                      $time);

        // ══════════════════════════════════
        // C2: resumereq → resume → running → allrunning
        // ══════════════════════════════════
        $display("─────────────────────────────────");
        $display("C2: resumereq → resume → running → allrunning");
        $display("─────────────────────────────────");

        // Assert resumereq
        #10;
        resumereq = 1;
        #10;
        resumereq = 0;

        // Check resume pulse
        #10;
        if (resume == 1)
            $display("Time=%0t: PASS: resume=1 pulsed to hart",
                      $time);
        else
            $display("Time=%0t: FAIL: resume not pulsed",
                      $time);

        // Check resume deasserts next cycle
        #10;
        if (resume == 0)
            $display("Time=%0t: PASS: resume=0 deasserted",
                      $time);
        else
            $display("Time=%0t: FAIL: resume stuck high",
                      $time);

        // Simulate hart confirming resume
        halted  = 0;
        running = 1;
        #10;

        // allrunning should be 1
        if (allrunning == 1 && allhalted == 0)
            $display("Time=%0t: PASS: allrunning=1 allhalted=0",
                      $time);
        else
            $display("Time=%0t: FAIL: allrunning=%0b allhalted=%0b",
                      $time, allrunning, allhalted);

        // ══════════════════════════════════
        // C3: haltreq + resumereq same cycle
        //     HALT WINS
        // ══════════════════════════════════
        $display("─────────────────────────────────");
        $display("C3: haltreq + resumereq same cycle — halt wins");
        $display("─────────────────────────────────");

        // Assert BOTH same cycle
        #10;
        haltreq  = 1;
        resumereq= 1;  // both same time!
        #10;
        haltreq  = 0;
        resumereq= 0;

        // Check halt wins
        #10;
        if (halt == 1 && resume == 0)
            $display("Time=%0t: PASS: halt wins over resume",
                      $time);
        else
            $display("Time=%0t: FAIL: halt=%0b resume=%0b",
                      $time, halt, resume);

        // Confirm hart halted
        halted  = 1;
        running = 0;
        #10;
        if (allhalted == 1)
            $display("Time=%0t: PASS: allhalted=1 halt won",
                      $time);
        else
            $display("Time=%0t: FAIL: allhalted not set",
                      $time);

        // ══════════════════════════════════
        // C4: Spontaneous un-halt (NMI)
        //     DM detects via falling halted
        // ══════════════════════════════════
        $display("─────────────────────────────────");
        $display("C4: Spontaneous un-halt — DM detects");
        $display("─────────────────────────────────");

        // Hart spontaneously un-halts (NMI)
        // No resumereq from debugger!
        #10;
        $display("Time=%0t: Hart spontaneously un-halts (NMI)",
                  $time);
        halted  = 0;  // hart drops halted
        running = 1;  // hart starts running
        #10;

        // DM must detect this
        if (allhalted  == 0 &&
            allrunning == 1)
            $display("Time=%0t: PASS: DM detected spontaneous un-halt",
                      $time);
        else
            $display("Time=%0t: FAIL: allhalted=%0b allrunning=%0b",
                      $time, allhalted, allrunning);

        // Verify no resume signal was sent
        if (resume == 0)
            $display("Time=%0t: PASS: resume=0 DM did not send resume",
                      $time);
        else
            $display("Time=%0t: FAIL: resume incorrectly asserted",
                      $time);

        $display("─────────────────────────────────");
        $display("Time=%0t: All Part C tests done",
                  $time);
        $finish;
    end

endmodule