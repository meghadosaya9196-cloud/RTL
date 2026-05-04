//==================================================================
// apb_slave.sv
// Parameterised APB-slave register bank for the DRAM refresh
// scheduler. Latches PSLVERR on illegal address, exposes a sticky
// error-status register, and provides a software-cleared error path.
//
// Address Map (word-aligned)
//  0x00  CONTROL          [0]=enable    [1]=clear_error (W1C pulse)
//  0x04  STATUS           [0]=refresh_req  [2:0]=fsm_state
//                         [4]=timeout_error
//  0x08  REFRESH_INTERVAL refresh interval in clock cycles
//  0x0C  REFRESH_COUNT    completed refresh count (RO)
//  0x10  ERROR_STATUS     sticky error flags (W1C)
//==================================================================

module apb_refresh_scheduler #(
    parameter int ADDR_WIDTH = 8,
    parameter int DATA_WIDTH = 32,
    parameter int CNT_WIDTH  = 32
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
    // Connections to Scheduler Core
    //--------------------------------------------------
    output logic                  enable,
    output logic                  clear_error,
    output logic [CNT_WIDTH-1:0]  refresh_interval,

    input  logic                  refresh_req,
    input  logic                  refresh_done_pulse,
    input  logic                  timeout_error,
    input  logic [2:0]            fsm_state
);

    //--------------------------------------------------
    // Address Map
    //--------------------------------------------------
    localparam logic [ADDR_WIDTH-1:0] CONTROL_ADDR          = 'h00;
    localparam logic [ADDR_WIDTH-1:0] STATUS_ADDR           = 'h04;
    localparam logic [ADDR_WIDTH-1:0] REFRESH_INTERVAL_ADDR = 'h08;
    localparam logic [ADDR_WIDTH-1:0] REFRESH_COUNT_ADDR    = 'h0C;
    localparam logic [ADDR_WIDTH-1:0] ERROR_STATUS_ADDR     = 'h10;

    //--------------------------------------------------
    // Internal Registers
    //--------------------------------------------------
    logic [DATA_WIDTH-1:0] control_reg;
    logic [DATA_WIDTH-1:0] refresh_interval_reg;
    logic [CNT_WIDTH-1:0]  refresh_count_reg;
    logic [DATA_WIDTH-1:0] error_status_reg;

    //--------------------------------------------------
    // Address-decode helper
    //--------------------------------------------------
    logic addr_legal;
    always_comb
    begin
        unique case (PADDR)
            CONTROL_ADDR,
            STATUS_ADDR,
            REFRESH_INTERVAL_ADDR,
            REFRESH_COUNT_ADDR,
            ERROR_STATUS_ADDR : addr_legal = 1'b1;
            default           : addr_legal = 1'b0;
        endcase
    end

    //--------------------------------------------------
    // APB Ready (zero-wait-state slave)
    //--------------------------------------------------
    assign PREADY = 1'b1;

    //--------------------------------------------------
    // PSLVERR — asserted on illegal address during access phase
    //--------------------------------------------------
    assign PSLVERR = PSEL && PENABLE && !addr_legal;

    //--------------------------------------------------
    // Write Logic + Sticky Error / Counter
    //--------------------------------------------------
    logic apb_write_strobe;
    assign apb_write_strobe = PSEL && PENABLE && PWRITE && addr_legal;

    // clear_error is a single-cycle pulse derived from CONTROL[1]
    assign clear_error = apb_write_strobe && (PADDR == CONTROL_ADDR) && PWDATA[1];

    always_ff @(posedge PCLK or negedge PRESETn)
    begin
        if (!PRESETn)
        begin
            control_reg          <= '0;
            refresh_interval_reg <= 'd100;
            refresh_count_reg    <= '0;
            error_status_reg     <= '0;
        end
        else
        begin

            //----------------------------------------
            // Register Writes
            //----------------------------------------
            if (apb_write_strobe)
            begin
                unique case (PADDR)

                    CONTROL_ADDR:
                        // bit[1] is auto-clear (pulse), keep bit[0]=enable
                        control_reg <= {PWDATA[DATA_WIDTH-1:2], 1'b0, PWDATA[0]};

                    REFRESH_INTERVAL_ADDR:
                        refresh_interval_reg <= PWDATA;

                    ERROR_STATUS_ADDR:
                        // W1C — write 1 to a bit to clear it
                        error_status_reg <= error_status_reg & ~PWDATA;

                    default: ;

                endcase
            end

            //----------------------------------------
            // Refresh-completion counter (RO from APB)
            //----------------------------------------
            if (refresh_done_pulse)
                refresh_count_reg <= refresh_count_reg + 1'b1;

            //----------------------------------------
            // Sticky timeout flag in ERROR_STATUS[0]
            //----------------------------------------
            if (timeout_error)
                error_status_reg[0] <= 1'b1;

            //----------------------------------------
            // Sticky illegal-address flag in ERROR_STATUS[1]
            //----------------------------------------
            if (PSEL && PENABLE && !addr_legal)
                error_status_reg[1] <= 1'b1;

        end
    end

    //--------------------------------------------------
    // Drive Core Control Outputs
    //--------------------------------------------------
    assign enable           = control_reg[0];
    assign refresh_interval = refresh_interval_reg[CNT_WIDTH-1:0];

    //--------------------------------------------------
    // Read Logic
    //--------------------------------------------------
    logic [DATA_WIDTH-1:0] status_reg;
    always_comb
    begin
        status_reg       = '0;
        status_reg[0]    = refresh_req;
        status_reg[3:1]  = fsm_state;
        status_reg[4]    = timeout_error;
    end

    always_comb
    begin
        PRDATA = '0;
        unique case (PADDR)
            CONTROL_ADDR          : PRDATA = control_reg;
            STATUS_ADDR           : PRDATA = status_reg;
            REFRESH_INTERVAL_ADDR : PRDATA = refresh_interval_reg;
            REFRESH_COUNT_ADDR    : PRDATA = { {(DATA_WIDTH-CNT_WIDTH){1'b0}}, refresh_count_reg };
            ERROR_STATUS_ADDR     : PRDATA = error_status_reg;
            default               : PRDATA = 32'hDEAD_BEEF;
        endcase
    end

endmodule
