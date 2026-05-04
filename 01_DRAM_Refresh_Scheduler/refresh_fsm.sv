//==================================================================
// refresh_fsm.sv
// 6-state refresh scheduler FSM with timeout protection.
//
// States: IDLE -> WAIT_FOR_REFRESH -> REQUEST_REFRESH ->
//         WAIT_FOR_ACK -> {COMPLETE | ERROR}
//
// If refresh_ack is not asserted within TIMEOUT_CYCLES of entering
// WAIT_FOR_ACK, the FSM transitions to ERROR and asserts
// timeout_error (sticky until cleared).
//==================================================================

module refresh_scheduler_fsm #(
    parameter int TIMEOUT_CYCLES = 64
)
(
    input  logic clk,
    input  logic rst_n,

    input  logic enable,
    input  logic clear_error,        // pulse from APB CONTROL[1] to clear ERROR

    input  logic refresh_due,
    input  logic refresh_ack,

    output logic refresh_req,
    output logic refresh_done_pulse,
    output logic timeout_error,

    output logic [2:0] state_dbg     // exposed for coverage / debug
);

    //--------------------------------------------------
    // Local Parameters
    //--------------------------------------------------

    localparam int TIMEOUT_W = (TIMEOUT_CYCLES <= 1) ? 1 : $clog2(TIMEOUT_CYCLES + 1);

    //--------------------------------------------------
    // FSM State Type
    //--------------------------------------------------

    typedef enum logic [2:0]
    {
        IDLE             = 3'd0,
        WAIT_FOR_REFRESH = 3'd1,
        REQUEST_REFRESH  = 3'd2,
        WAIT_FOR_ACK     = 3'd3,
        COMPLETE         = 3'd4,
        ERROR            = 3'd5
    } state_t;

    state_t current_state, next_state;

    logic [TIMEOUT_W-1:0] timeout_counter;
    logic                 timeout_hit;

    //--------------------------------------------------
    // State Register
    //--------------------------------------------------

    always_ff @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    //--------------------------------------------------
    // Timeout Counter
    //--------------------------------------------------

    assign timeout_hit = (timeout_counter >= TIMEOUT_CYCLES[TIMEOUT_W-1:0]);

    always_ff @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
            timeout_counter <= '0;
        else if (current_state == WAIT_FOR_ACK)
            timeout_counter <= timeout_counter + 1'b1;
        else
            timeout_counter <= '0;
    end

    //--------------------------------------------------
    // Sticky Error Flag
    //--------------------------------------------------

    always_ff @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
            timeout_error <= 1'b0;
        else if (clear_error)
            timeout_error <= 1'b0;
        else if ((current_state == WAIT_FOR_ACK) && timeout_hit)
            timeout_error <= 1'b1;
    end

    //--------------------------------------------------
    // Next-State Logic
    //--------------------------------------------------

    always_comb
    begin
        next_state = current_state;

        unique case (current_state)

            IDLE:
                if (enable)
                    next_state = WAIT_FOR_REFRESH;

            WAIT_FOR_REFRESH:
            begin
                if (!enable)
                    next_state = IDLE;
                else if (refresh_due)
                    next_state = REQUEST_REFRESH;
            end

            REQUEST_REFRESH:
                next_state = WAIT_FOR_ACK;

            WAIT_FOR_ACK:
            begin
                if (refresh_ack)
                    next_state = COMPLETE;
                else if (timeout_hit)
                    next_state = ERROR;
            end

            COMPLETE:
                next_state = WAIT_FOR_REFRESH;

            ERROR:
            begin
                // Stay in ERROR until software clears it via APB
                if (clear_error)
                    next_state = IDLE;
            end

            default:
                next_state = IDLE;

        endcase
    end

    //--------------------------------------------------
    // Output Logic
    //--------------------------------------------------

    always_comb
    begin
        refresh_req        = 1'b0;
        refresh_done_pulse = 1'b0;

        unique case (current_state)
            REQUEST_REFRESH: refresh_req        = 1'b1;
            WAIT_FOR_ACK   : refresh_req        = 1'b1;
            COMPLETE       : refresh_done_pulse = 1'b1;
            default        : ;
        endcase
    end

    assign state_dbg = current_state;

endmodule