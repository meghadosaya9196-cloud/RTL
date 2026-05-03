`timescale 1ns/1ps

module tb_debug_module;

    // ─────────────────────────────────────
    // Signal Declarations
    // ─────────────────────────────────────
    logic        clk;
    logic        rst;
    logic [1:0]  dmi_op    = 2'b00;
    logic [6:0]  dmi_addr  = 7'h0;
    logic [31:0] dmi_wdata = 32'h0;
    logic [1:0]  dmi_resp;
    logic [31:0] dmi_rdata;
    logic        halt;
    logic        resume;
    logic        halted   = 1'b0;
    logic        running  = 1'b1;
    logic        hart_req_valid;
    logic        hart_req_write;
    logic [15:0] hart_req_addr;
    logic [31:0] hart_req_wdata;
    logic        hart_resp_valid = 1'b0;
    logic [31:0] hart_resp_rdata = 32'h0;

    // Hart storage
    logic [31:0] gpr[0:31];
    logic [31:0] mtvec   = 32'h0;
    logic [31:0] mstatus = 32'h0;

    // ─────────────────────────────────────
    // DUT Instantiation
    // ─────────────────────────────────────
    debug_module dut (
        .clk            (clk),
        .rst            (rst),
        .dmi_op         (dmi_op),
        .dmi_addr       (dmi_addr),
        .dmi_wdata      (dmi_wdata),
        .dmi_resp       (dmi_resp),
        .dmi_rdata      (dmi_rdata),
        .halt           (halt),
        .resume         (resume),
        .halted         (halted),
        .running        (running),
        .hart_req_valid (hart_req_valid),
        .hart_req_write (hart_req_write),
        .hart_req_addr  (hart_req_addr),
        .hart_req_wdata (hart_req_wdata),
        .hart_resp_valid(hart_resp_valid),
        .hart_resp_rdata(hart_resp_rdata)
    );

    // ─────────────────────────────────────
    // Clock
    // ─────────────────────────────────────
    initial clk = 0;
    always #5 clk = ~clk;

    // ─────────────────────────────────────
    // GPR Initialization
    // ─────────────────────────────────────
    integer k;
    initial begin
        for (k = 0; k < 32; k = k+1)
            gpr[k] = 32'h0;
        gpr[5] = 32'hDEADBEEF;
        $display("GPR init: gpr[5]=0x%h", gpr[5]);
    end

    // ─────────────────────────────────────
    // Hart Stub Behavior
    // ─────────────────────────────────────
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            halted          <= 1'b0;
            running         <= 1'b1;
            hart_resp_valid <= 1'b0;
            hart_resp_rdata <= 32'h0;
            mtvec           <= 32'h0;
            mstatus         <= 32'h0;
        end
        else begin
            // Halt response
            if (halt) begin
                halted  <= 1'b1;
                running <= 1'b0;
            end

            // Resume response
            if (resume) begin
                halted  <= 1'b0;
                running <= 1'b1;
            end

            // Default deassert valid only
            hart_resp_valid <= 1'b0;

            // Register access
            if (hart_req_valid &&
                !hart_resp_valid) begin

                hart_resp_valid <= 1'b1;

                if (!hart_req_write) begin
                    // READ
                    if (hart_req_addr >= 16'h1000 &&
                        hart_req_addr <= 16'h101F)
                        hart_resp_rdata <=
                            gpr[hart_req_addr - 16'h1000];
                    else
                        case (hart_req_addr)
                            16'h0305:
                                hart_resp_rdata <= mtvec;
                            16'h0300:
                                hart_resp_rdata <= mstatus;
                            default:
                                hart_resp_rdata <= 32'h0;
                        endcase
                end
                else begin
                    // WRITE — clear rdata, update storage
                    hart_resp_rdata <= 32'h0;
                    if (hart_req_addr >= 16'h1000 &&
                        hart_req_addr <= 16'h101F)
                        gpr[hart_req_addr - 16'h1000]
                            <= hart_req_wdata;
                    else
                        case (hart_req_addr)
                            16'h0305:
                                mtvec <= hart_req_wdata;
                            16'h0300:
                                mstatus <= hart_req_wdata;
                        endcase
                end
            end
        end
    end

    // ─────────────────────────────────────
    // DMI Tasks
    // ─────────────────────────────────────
    task dmi_write(
        input [6:0]  a,
        input [31:0] d
    );
        @(posedge clk); #1;
        dmi_op    = 2'b10;
        dmi_addr  = a;
        dmi_wdata = d;
        @(posedge clk); #1;
        dmi_op   = 2'b00;
        dmi_addr = 7'h0;
        @(posedge clk);
        @(posedge clk);
        $display("  DMI WRITE addr=0x%h data=0x%h", a, d);
    endtask

    task dmi_read(
        input  [6:0]  a,
        output [31:0] d
    );
        @(posedge clk); #1;
        dmi_op   = 2'b01;
        dmi_addr = a;
        @(posedge clk);
        @(posedge clk); #1;
        d        = dmi_rdata;
        dmi_op   = 2'b00;
        dmi_addr = 7'h0;
        @(posedge clk);
        $display("  DMI READ  addr=0x%h data=0x%h", a, d);
    endtask

    task wait_not_busy;
        logic [31:0] val;
        integer cnt;
        cnt = 0;
        repeat(100) begin
            dmi_read(7'h16, val);
            if (!val[12]) begin
                $display("  abstractcs.busy=0 done");
                return;
            end
            cnt = cnt + 1;
        end
        $display("  TIMEOUT: busy never cleared!");
    endtask

    // ─────────────────────────────────────
    // Main Test
    // ─────────────────────────────────────
    logic [31:0] rval;

    initial begin
        rst       = 1;
        dmi_op    = 2'b00;
        dmi_addr  = 7'h0;
        dmi_wdata = 32'h0;

        repeat(5) @(posedge clk);
        rst = 0;
        repeat(3) @(posedge clk);

        // ══════════════════════════════════
        // SCENARIO 1: Full GPR access path
        // ══════════════════════════════════
        $display("════════════════════════════════════");
        $display("SCENARIO 1: Full GPR access path");
        $display("════════════════════════════════════");

        // Step 1: Activate DM
        $display("--- Step 1: Activate DM ---");
        dmi_write(7'h10, 32'h00000001);

        // Step 2: Read dmstatus
        $display("--- Step 2: Read dmstatus ---");
        dmi_read(7'h11, rval);
        if (rval[3:0] == 4'h2)
            $display("  PASS: version=2");
        else
            $display("  FAIL: version=0x%h expected 2", rval[3:0]);

        // Step 3: Halt hart
        $display("--- Step 3: Halt hart ---");
        dmi_write(7'h10, 32'h80000001);
        wait(halted == 1);
        repeat(3) @(posedge clk);
        dmi_write(7'h10, 32'h00000001);
        repeat(2) @(posedge clk);
        dmi_read(7'h11, rval);
        if (rval[9] == 1'b1)
            $display("  PASS: allhalted=1");
        else
            $display("  FAIL: allhalted=0 dmstatus=0x%h", rval);

        // Step 4: Read GPR x5
        $display("--- Step 4: Read GPR x5 ---");
        dmi_write(7'h17, 32'h00221005);
        wait_not_busy();
        dmi_read(7'h04, rval);
        if (rval == 32'hDEADBEEF)
            $display("  PASS: x5=0x%h", rval);
        else
            $display("  FAIL: x5=0x%h expected DEADBEEF", rval);

        // Step 5: Write GPR x5 = 0xCAFEBABE
        $display("--- Step 5: Write GPR x5 ---");
        dmi_write(7'h04, 32'hCAFEBABE);
        repeat(2) @(posedge clk);  // let data0_r settle
        dmi_write(7'h17, 32'h00231005);
        wait_not_busy();
        $display("  Write x5=0xCAFEBABE done");

        // Step 6: Read back x5
        $display("--- Step 6: Read-back x5 ---");
        dmi_write(7'h17, 32'h00221005);
        wait_not_busy();
        dmi_read(7'h04, rval);
        if (rval == 32'hCAFEBABE)
            $display("  PASS: x5=0x%h", rval);
        else
            $display("  FAIL: x5=0x%h expected CAFEBABE", rval);

        // Step 7: Resume hart
        $display("--- Step 7: Resume hart ---");
        dmi_write(7'h10, 32'h40000001);
        wait(running == 1);
        repeat(3) @(posedge clk);
        dmi_write(7'h10, 32'h00000001);
        repeat(2) @(posedge clk);
        dmi_read(7'h11, rval);
        if (rval[11] == 1'b1)
            $display("  PASS: allrunning=1");
        else
            $display("  FAIL: allrunning=0");

        $display("SCENARIO 1: COMPLETE");

        // ══════════════════════════════════
        // SCENARIO 2: Error path + recovery
        // ══════════════════════════════════
        $display("════════════════════════════════════");
        $display("SCENARIO 2: Error path + recovery");
        $display("════════════════════════════════════");

        // Step 1: Send command while running
        $display("--- Step 1: Cmd while running ---");
        dmi_write(7'h17, 32'h00221005);
        repeat(5) @(posedge clk);
        dmi_read(7'h16, rval);
        if (rval[10:8] == 3'd4)
            $display("  PASS: cmderr=4 halt mismatch");
        else
            $display("  FAIL: cmderr=%0d expected 4", rval[10:8]);

        // Step 2: Halt hart
        $display("--- Step 2: Halt hart ---");
        dmi_write(7'h10, 32'h80000001);
        wait(halted == 1);
        repeat(3) @(posedge clk);
        dmi_write(7'h10, 32'h00000001);

        // Step 3: Clear cmderr W1C
        $display("--- Step 3: Clear cmderr ---");
        dmi_write(7'h16, 32'h00000700);
        repeat(2) @(posedge clk);
        dmi_read(7'h16, rval);
        if (rval[10:8] == 3'd0)
            $display("  PASS: cmderr cleared");
        else
            $display("  FAIL: cmderr=%0d not cleared", rval[10:8]);

        // Step 4: Retry read x5
        $display("--- Step 4: Retry read x5 ---");
        dmi_write(7'h17, 32'h00221005);
        wait_not_busy();
        dmi_read(7'h04, rval);
        if (rval == 32'hCAFEBABE)
            $display("  PASS: retry x5=0x%h", rval);
        else
            $display("  FAIL: x5=0x%h expected CAFEBABE", rval);

        $display("SCENARIO 2: COMPLETE");

        // ══════════════════════════════════
        // SCENARIO 3: CSR path — mtvec
        // ══════════════════════════════════
        $display("════════════════════════════════════");
        $display("SCENARIO 3: CSR path — mtvec");
        $display("════════════════════════════════════");

        // Step 1: Write mtvec = 0xABCD1234
        $display("--- Step 1: Write mtvec CSR ---");
        dmi_write(7'h04, 32'hABCD1234);
        repeat(2) @(posedge clk);  // let data0_r settle
        dmi_write(7'h17, 32'h00230305);
        wait_not_busy();
        $display("  Write mtvec=0xABCD1234 done");

        // Step 2: Read back mtvec
        $display("--- Step 2: Read back mtvec ---");
        dmi_write(7'h17, 32'h00220305);
        wait_not_busy();
        dmi_read(7'h04, rval);
        if (rval == 32'hABCD1234)
            $display("  PASS: mtvec=0x%h confirmed", rval);
        else
            $display("  FAIL: mtvec=0x%h expected ABCD1234", rval);

        $display("SCENARIO 3: COMPLETE");
        $display("════════════════════════════════════");
        $display("All Part D scenarios complete");
        $display("════════════════════════════════════");
        $finish;
    end

endmodule
