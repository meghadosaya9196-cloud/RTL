//==================================================================
// TB_Top_Integration.sv  (simplified for XSim compile speed)
//
// - Directed reset / programming
// - Inline random APB transactions (no class, no dist constraints)
// - Forced timeout to exercise the ERROR path
// - 2 SVA assertions
// - Covergroup with 4 coverpoints (>3 bins total)
//==================================================================

`timescale 1ns/1ps

module tb_refresh_scheduler_top;

    //--------------------------------------------------
    // Parameters
    //--------------------------------------------------
    localparam int ADDR_WIDTH     = 8;
    localparam int DATA_WIDTH     = 32;
    localparam int TIMEOUT_CYCLES = 64;

    localparam logic [7:0] CONTROL_ADDR          = 8'h00;
    localparam logic [7:0] STATUS_ADDR           = 8'h04;
    localparam logic [7:0] REFRESH_INTERVAL_ADDR = 8'h08;
    localparam logic [7:0] REFRESH_COUNT_ADDR    = 8'h0C;
    localparam logic [7:0] ERROR_STATUS_ADDR     = 8'h10;

    localparam logic [2:0] S_IDLE             = 3'd0;
    localparam logic [2:0] S_WAIT_FOR_REFRESH = 3'd1;
    localparam logic [2:0] S_REQUEST_REFRESH  = 3'd2;
    localparam logic [2:0] S_WAIT_FOR_ACK     = 3'd3;
    localparam logic [2:0] S_COMPLETE         = 3'd4;
    localparam logic [2:0] S_ERROR            = 3'd5;

    //--------------------------------------------------
    // Signals
    //--------------------------------------------------
    logic                  PCLK;
    logic                  PRESETn;
    logic                  PSEL, PENABLE, PWRITE;
    logic [ADDR_WIDTH-1:0] PADDR;
    logic [DATA_WIDTH-1:0] PWDATA;
    logic [DATA_WIDTH-1:0] PRDATA;
    logic                  PREADY, PSLVERR;
    logic                  refresh_ack, refresh_req;

    //--------------------------------------------------
    // DUT
    //--------------------------------------------------
    refresh_scheduler_top dut (
        .PCLK        (PCLK),
        .PRESETn     (PRESETn),
        .PSEL        (PSEL),
        .PENABLE     (PENABLE),
        .PWRITE      (PWRITE),
        .PADDR       (PADDR),
        .PWDATA      (PWDATA),
        .PRDATA      (PRDATA),
        .PREADY      (PREADY),
        .PSLVERR     (PSLVERR),
        .refresh_ack (refresh_ack),
        .refresh_req (refresh_req)
    );

    //--------------------------------------------------
    // Clock
    //--------------------------------------------------
    initial PCLK = 0;
    always  #5 PCLK = ~PCLK;     // 100 MHz

    //--------------------------------------------------
    // Simple BFM tasks
    //--------------------------------------------------
    task automatic apb_write(input [7:0] addr, input [31:0] data);
        begin
            @(posedge PCLK);
            PSEL <= 1; PENABLE <= 0; PWRITE <= 1;
            PADDR <= addr; PWDATA <= data;
            @(posedge PCLK); PENABLE <= 1;
            @(posedge PCLK); PSEL <= 0; PENABLE <= 0; PWRITE <= 0;
        end
    endtask

    task automatic apb_read(input [7:0] addr, output [31:0] data);
        begin
            @(posedge PCLK);
            PSEL <= 1; PENABLE <= 0; PWRITE <= 0; PADDR <= addr;
            @(posedge PCLK); PENABLE <= 1;
            @(posedge PCLK); data = PRDATA; PSEL <= 0; PENABLE <= 0;
        end
    endtask

    //--------------------------------------------------
    // Refresh ACK model
    //--------------------------------------------------
    bit force_timeout;

    initial begin
        refresh_ack = 0;
        forever begin
            @(posedge refresh_req);
            if (force_timeout) begin
                repeat (TIMEOUT_CYCLES + 10) @(posedge PCLK);
                force_timeout = 0;
            end
            else begin
                repeat ($urandom_range(8, 1)) @(posedge PCLK);
                refresh_ack <= 1;
                @(posedge PCLK);
                refresh_ack <= 0;
            end
        end
    end

    //--------------------------------------------------
    // Functional Coverage  (4 coverpoints, > 3 bins)
    //--------------------------------------------------
    covergroup cg @(posedge PCLK);
        cp_state : coverpoint dut.u_fsm.state_dbg {
            bins idle     = {S_IDLE};
            bins waiting  = {S_WAIT_FOR_REFRESH};
            bins request  = {S_REQUEST_REFRESH};
            bins wait_ack = {S_WAIT_FOR_ACK};
            bins complete = {S_COMPLETE};
            bins err      = {S_ERROR};
        }
        cp_pslverr : coverpoint PSLVERR {
            bins ok       = {0};
            bins illegal  = {1};
        }
        cp_timeout : coverpoint dut.u_fsm.timeout_error {
            bins no_to    = {0};
            bins to       = {1};
        }
        cp_req : coverpoint refresh_req {
            bins low      = {0};
            bins high     = {1};
        }
    endgroup

    cg cg_inst = new();

    //--------------------------------------------------
    // SVA Assertions
    //--------------------------------------------------
    property p_req_ack_or_timeout;
        @(posedge PCLK) disable iff (!PRESETn)
            $rose(refresh_req) |->
                ##[1:TIMEOUT_CYCLES+2]
                    (refresh_ack || dut.u_fsm.state_dbg == S_ERROR);
    endproperty
    a_req_ack_or_timeout : assert property (p_req_ack_or_timeout)
        else $error("[SVA] refresh_req not acked and no timeout");

    property p_done_pulse_one_cycle;
        @(posedge PCLK) disable iff (!PRESETn)
            $rose(dut.refresh_done_pulse) |=> !dut.refresh_done_pulse;
    endproperty
    a_done_pulse : assert property (p_done_pulse_one_cycle)
        else $error("[SVA] refresh_done_pulse > 1 cycle");

    //--------------------------------------------------
    // Stimulus
    //--------------------------------------------------
    logic [31:0] rdata;
    logic [7:0]  rand_addr;
    integer      i;

    initial begin
        PSEL = 0; PENABLE = 0; PWRITE = 0;
        PADDR = 0; PWDATA = 0;
        PRESETn = 0;
        force_timeout = 0;

        repeat (5) @(posedge PCLK);
        PRESETn = 1;
        repeat (2) @(posedge PCLK);

        // Directed: program and enable
        apb_write(REFRESH_INTERVAL_ADDR, 32'd20);
        apb_write(CONTROL_ADDR,          32'h1);
        repeat (150) @(posedge PCLK);

        // Force a timeout, recover
        force_timeout = 1;
        wait (dut.u_fsm.state_dbg == S_ERROR);
        repeat (5) @(posedge PCLK);
        apb_read(ERROR_STATUS_ADDR, rdata);
        $display("[%0t] ERROR_STATUS = 0x%08h", $time, rdata);
        apb_write(CONTROL_ADDR,      32'h3);     // enable + clear_error
        apb_write(ERROR_STATUS_ADDR, 32'h1);     // W1C
        repeat (150) @(posedge PCLK);

        // Inline-random APB activity (no class, no dist)
        for (i = 0; i < 30; i = i + 1) begin
            rand_addr = $urandom_range(8'h20, 8'h00);    // mix of legal + illegal
            if ($urandom_range(1,0)) begin
                apb_write(rand_addr, $urandom);
            end else begin
                apb_read(rand_addr, rdata);
            end
            repeat ($urandom_range(4,1)) @(posedge PCLK);
        end

        repeat (200) @(posedge PCLK);

        $display("============================================");
        $display(" Functional coverage = %0.2f %%", cg_inst.get_inst_coverage());
        $display("============================================");
        $finish;
    end

    //--------------------------------------------------
    // Watchdog
    //--------------------------------------------------
    initial begin
        #200_000;
        $display("[%0t] Watchdog expired", $time);
        $finish;
    end

endmodule