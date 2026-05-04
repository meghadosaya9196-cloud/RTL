//==================================================================
// Top_Integration.sv
// Top-level wrapper that wires together:
//   * apb_refresh_scheduler   (APB register bank, error path)
//   * refresh_timer           (programmable interval timer)
//   * refresh_scheduler_fsm   (6-state scheduler with timeout)
//
// All widths and the timeout depth are parameterised and propagated
// down so the same RTL can be synthesised in multiple configurations.
//==================================================================

module refresh_scheduler_top #(
    parameter int ADDR_WIDTH     = 8,
    parameter int DATA_WIDTH     = 32,
    parameter int CNT_WIDTH      = 32,
    parameter int TIMEOUT_CYCLES = 64
)
(
    //--------------------------------------------------
    // APB Interface
    //--------------------------------------------------
    input  logic                  PCLK,
    input  logic                  PRESETn,

    input  logic                  PSEL,
    input  logic                  PENABLE,
    input  logic                  PWRITE,

    input  logic [ADDR_WIDTH-1:0] PADDR,
    input  logic [DATA_WIDTH-1:0] PWDATA,

    output logic [DATA_WIDTH-1:0] PRDATA,
    output logic                  PREADY,
    output logic                  PSLVERR,

    //--------------------------------------------------
    // DRAM Refresh Handshake
    //--------------------------------------------------
    input  logic                  refresh_ack,
    output logic                  refresh_req
);

    //--------------------------------------------------
    // Internal Wires
    //--------------------------------------------------
    logic                  enable;
    logic                  clear_error;
    logic [CNT_WIDTH-1:0]  refresh_interval;
    logic [CNT_WIDTH-1:0]  refresh_counter;
    logic                  refresh_due;
    logic                  refresh_done_pulse;
    logic                  timeout_error;
    logic [2:0]            fsm_state;

    //--------------------------------------------------
    // APB Register Bank
    //--------------------------------------------------
    apb_refresh_scheduler #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .CNT_WIDTH  (CNT_WIDTH)
    ) u_apb (
        .PCLK              (PCLK),
        .PRESETn           (PRESETn),
        .PSEL              (PSEL),
        .PENABLE           (PENABLE),
        .PWRITE            (PWRITE),
        .PADDR             (PADDR),
        .PWDATA            (PWDATA),
        .PRDATA            (PRDATA),
        .PREADY            (PREADY),
        .PSLVERR           (PSLVERR),

        .enable            (enable),
        .clear_error       (clear_error),
        .refresh_interval  (refresh_interval),
        .refresh_req       (refresh_req),
        .refresh_done_pulse(refresh_done_pulse),
        .timeout_error     (timeout_error),
        .fsm_state         (fsm_state)
    );

    //--------------------------------------------------
    // Refresh Interval Timer
    //--------------------------------------------------
    refresh_timer #(
        .CNT_WIDTH (CNT_WIDTH)
    ) u_timer (
        .clk              (PCLK),
        .rst_n            (PRESETn),
        .enable           (enable),
        .refresh_interval (refresh_interval),
        .refresh_due      (refresh_due),
        .refresh_counter  (refresh_counter)
    );

    //--------------------------------------------------
    // Refresh Scheduler FSM
    //--------------------------------------------------
    refresh_scheduler_fsm #(
        .TIMEOUT_CYCLES (TIMEOUT_CYCLES)
    ) u_fsm (
        .clk                (PCLK),
        .rst_n              (PRESETn),
        .enable             (enable),
        .clear_error        (clear_error),
        .refresh_due        (refresh_due),
        .refresh_ack        (refresh_ack),
        .refresh_req        (refresh_req),
        .refresh_done_pulse (refresh_done_pulse),
        .timeout_error      (timeout_error),
        .state_dbg          (fsm_state)
    );

endmodule