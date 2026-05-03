`timescale 1ns/1ps

module abstract_cmd_fsm (
    input  logic        clk,
    input  logic        rst_n,

    // Command interface
    input  logic        cmd_valid,
    input  logic [31:0] command_reg,
    input  logic [31:0] data0_in,

    // Hart interface
    input  logic        hart_halted,
    input  logic        hart_resp_valid,
    input  logic [31:0] hart_resp_rdata,
    output logic        hart_req_valid,
    output logic        hart_req_write,
    output logic [15:0] hart_req_addr,
    output logic [31:0] hart_req_wdata,

    // Outputs to regfile
    output logic [31:0] data0_out,
    output logic        busy,
    output logic [2:0]  cmderr
);

    // ─────────────────────────────────────
    // State Definition
    // ─────────────────────────────────────
    typedef enum logic [2:0] {
        ABS_IDLE       = 3'b000,
        ABS_DECODE     = 3'b001,
        ABS_EXEC_READ  = 3'b010,
        ABS_EXEC_WRITE = 3'b011,
        ABS_DONE       = 3'b100
    } state_t;

    state_t state, next_state;

    // ─────────────────────────────────────
    // Command Field Extractions
    // ─────────────────────────────────────
    logic [7:0]  cmdtype;
    logic [2:0]  aarsize;
    logic        transfer;
    logic        write;
    logic [15:0] regno;

    assign cmdtype  = command_reg[31:24];
    assign aarsize  = command_reg[22:20];
    assign transfer = command_reg[17];
    assign write    = command_reg[16];
    assign regno    = command_reg[15:0];

    // ─────────────────────────────────────
    // Latched regno — stable in EXEC states
    // ─────────────────────────────────────
    logic [15:0] regno_lat;

    // ─────────────────────────────────────
    // State Register
    // ─────────────────────────────────────
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= ABS_IDLE;
        else
            state <= next_state;
    end

    // ─────────────────────────────────────
    // Next State Logic — combinational
    // ─────────────────────────────────────
    always_comb begin
        next_state = state;

        case (state)

            // ─────────────────────────────
            // ABS_IDLE
            // Entry:  reset / cmd done
            // Action: wait for cmd_valid
            // Exit:   cmd_valid → DECODE
            // ─────────────────────────────
            ABS_IDLE: begin
                if (cmd_valid)
                    next_state = ABS_DECODE;
            end

            // ─────────────────────────────
            // ABS_DECODE
            // Entry:  cmd_valid received
            // Action: validate command
            // Exit:   valid → EXEC
            //         error → IDLE
            // ─────────────────────────────
            ABS_DECODE: begin
                if (cmdtype != 8'h00)
                    next_state = ABS_IDLE;
                else if (aarsize != 3'b010)
                    next_state = ABS_IDLE;
                else if (!transfer)
                    next_state = ABS_IDLE;
                else if (!hart_halted)
                    next_state = ABS_IDLE;
                else if (!write)
                    next_state = ABS_EXEC_READ;
                else
                    next_state = ABS_EXEC_WRITE;
            end

            // ─────────────────────────────
            // ABS_EXEC_READ
            // Entry:  write=0
            // Action: read from hart
            // Exit:   hart_resp_valid → DONE
            // ─────────────────────────────
            ABS_EXEC_READ: begin
                if (hart_resp_valid)
                    next_state = ABS_DONE;
            end

            // ─────────────────────────────
            // ABS_EXEC_WRITE
            // Entry:  write=1
            // Action: write to hart
            // Exit:   hart_resp_valid → DONE
            // ─────────────────────────────
            ABS_EXEC_WRITE: begin
                if (hart_resp_valid)
                    next_state = ABS_DONE;
            end

            // ─────────────────────────────
            // ABS_DONE
            // Entry:  hart ack received
            // Action: clear busy
            // Exit:   always → IDLE
            // ─────────────────────────────
            ABS_DONE: begin
                next_state = ABS_IDLE;
            end

            default: next_state = ABS_IDLE;

        endcase
    end

    // ─────────────────────────────────────
    // Output Logic
    // Uses next_state for 1-cycle early
    // output so signals are ready when
    // state transitions happen
    // ─────────────────────────────────────
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy           <= 1'b0;
            cmderr         <= 3'b0;
            hart_req_valid <= 1'b0;
            hart_req_write <= 1'b0;
            hart_req_addr  <= 16'h0;
            hart_req_wdata <= 32'h0;
            data0_out      <= 32'h0;
            regno_lat      <= 16'h0;
        end
        else begin
            // Default deassert every cycle
            hart_req_valid <= 1'b0;

            case (next_state)

                // ─────────────────────────
                // Going to IDLE:
                // clear busy
                // preserve cmderr if error
                // ─────────────────────────
                ABS_IDLE: begin
                    busy <= 1'b0;
                    // Clear cmderr only on
                    // successful completion
                    if (state == ABS_DONE)
                        cmderr <= 3'b0;
                end

                // ─────────────────────────
                // Going to DECODE:
                // set busy
                // set error code
                // latch regno
                // ─────────────────────────
                ABS_DECODE: begin
                    busy      <= 1'b1;
                    regno_lat <= regno; // latch address

                    if (cmdtype != 8'h00)
                        cmderr <= 3'd2;
                    else if (aarsize != 3'b010)
                        cmderr <= 3'd2;
                    else if (!transfer)
                        cmderr <= 3'd2;
                    else if (!hart_halted)
                        cmderr <= 3'd4;
                    else
                        cmderr <= 3'd0;
                end

                // ─────────────────────────
                // Going to EXEC_READ:
                // assert req to hart
                // use latched regno
                // ─────────────────────────
                ABS_EXEC_READ: begin
                    hart_req_valid <= 1'b1;
                    hart_req_write <= 1'b0;
                    hart_req_addr  <= regno_lat;
                end

                // ─────────────────────────
                // Going to EXEC_WRITE:
                // assert req to hart
                // send data0_in value
                // ─────────────────────────
                ABS_EXEC_WRITE: begin
                    hart_req_valid <= 1'b1;
                    hart_req_write <= 1'b1;
                    hart_req_addr  <= regno_lat;
                    hart_req_wdata <= data0_in;
                end

                // ─────────────────────────
                // Going to DONE:
                // latch read result
                // deassert req
                // ─────────────────────────
                ABS_DONE: begin
                    hart_req_valid <= 1'b0;
                    busy           <= 1'b0;
                    if (state == ABS_EXEC_READ)
                        data0_out <= hart_resp_rdata;
                end

                default: begin
                    busy           <= 1'b0;
                    hart_req_valid <= 1'b0;
                end

            endcase
        end
    end

endmodule