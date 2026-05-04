module dm_regfile (
    input  logic        clk,
    input  logic        rst,

    // From dmi_slave
    input  logic        wen,
    input  logic [6:0]  addr,
    input  logic [31:0] wdata,
    output logic [31:0] rdata,

    // To halt_resume_ctrl
    output logic        haltreq,
    output logic        resumereq,
    output logic        dmactive,

    // From hart_stub
    input  logic        halted,
    input  logic        running,

    // To/From abs_cmd_fsm
    output logic [31:0] command_reg,
    output logic        cmd_valid,
    output logic        cmd_wr_while_busy,
    input  logic        busy,
    input  logic [2:0]  cmderr,
    output logic [31:0] data0_in,
    output logic [31:0] data1,
    input  logic [31:0] data0_out
);

    // ─────────────────────────────────────
    // Internal Register Storage
    // ─────────────────────────────────────
    logic [31:0] dmcontrol_r;
    logic [31:0] abstractcs_r;
    logic [31:0] command_r;
    logic [31:0] data0_r;
    logic [31:0] data1_r;
    logic busy_prev;

    // ─────────────────────────────────────
    // Field Extractions
    // ─────────────────────────────────────
    assign dmactive  = dmcontrol_r[0];
    assign haltreq   = dmcontrol_r[31];
    assign resumereq = dmcontrol_r[30];
    assign command_reg  = command_r;
    assign data0_in     = data0_r;
    assign data1     = data1_r;

    // dmstatus internal signals
    logic allhalted;
    logic allrunning;
    assign allhalted  = halted;
    assign allrunning = running;

    // ─────────────────────────────────────
    // Write Logic
    // ─────────────────────────────────────
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            dmcontrol_r       <= 32'h0;
            abstractcs_r      <= 32'h0;
            command_r         <= 32'h0;
            data0_r           <= 32'h0;
            data1_r           <= 32'h0;
            cmd_valid         <= 1'b0;
            cmd_wr_while_busy <= 1'b0;
            busy_prev<=1'b0;
        end
        else begin
            // Default clears every cycle
            cmd_valid         <= 1'b0;
            cmd_wr_while_busy <= 1'b0;

            // Always update abstractcs from FSM
            abstractcs_r[12]   <= busy;
            if (busy)
                abstractcs_r[10:8] <= cmderr;
            busy_prev <= busy;

            // data0 priority:
            // 1. Debugger write (highest priority)
            // 2. FSM result (when cmd completes)
            if (wen && addr == 7'h04 && dmactive && !busy)
                data0_r <= wdata;
            else if (busy_prev && !busy && data0_out != 32'h0)
                data0_r <= data0_out;

            // Write operations
            if (wen) begin
                case (addr)

                    // A3: dmcontrol ALWAYS writable
                    7'h10: begin
                        dmcontrol_r <= wdata;
                    end

                    // abstractcs — W1C cmderr only
                    7'h16: begin
                        if (dmactive) begin
                            if (|wdata[10:8]) 
                                abstractcs_r[10:8] <= 3'b0;
                        end
                    end

                    // command — only when not busy
                    7'h17: begin
                        if (dmactive && !busy) begin
                            command_r <= wdata;
                            cmd_valid <= 1'b1;
                        end
                        // cmderr=1: command written while busy
                        else if (dmactive && busy) begin
                            cmd_wr_while_busy <= 1'b1;
                        end
                    end

                    // data0 handled above
                    7'h04: ;

                    // data1
                    7'h05: begin
                        if (dmactive)
                            data1_r <= wdata;
                    end

                    default: ;
                endcase
            end
        end
    end

    // ─────────────────────────────────────
    // Read Logic
    // ─────────────────────────────────────
    always_comb begin
        case (addr)
            7'h04: rdata = data0_r;
            7'h05: rdata = data1_r;
            7'h10: rdata = dmcontrol_r;
            7'h11: rdata = {
                16'h0,
                4'h0,
                allrunning,
                allrunning,
                allhalted,
                allhalted,
                4'h0,
                4'h2
            };
            7'h12: rdata = 32'h0;
            7'h16: rdata = abstractcs_r;
            7'h17: rdata = command_r;
            default: rdata = 32'h0;
        endcase
    end

endmodule   