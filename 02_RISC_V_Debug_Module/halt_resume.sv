module halt_resume_ctrl (
    input  logic clk,
    input  logic rst,

    // From dm_regfile
    input  logic dmactive,
    input  logic haltreq,
    input  logic resumereq,

    // To hart_stub
    output logic halt,
    output logic resume,

    // From hart_stub
    input  logic halted,
    input  logic running,

    // To dm_regfile (dmstatus)
    output logic allhalted,
    output logic allrunning
);

    // ─────────────────────────────────────
    // Internal state tracking
    // ─────────────────────────────────────
    // Previous halted value
    // for detecting spontaneous un-halt (C4)
    logic halted_prev;

    // ─────────────────────────────────────
    // C1 + C2 + C3: Halt/Resume Control
    // ─────────────────────────────────────
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            halt        <= 1'b0;
            resume      <= 1'b0;
            halted_prev <= 1'b0;
        end
        else if (!dmactive) begin
            // DM inactive → deassert everything
            halt   <= 1'b0;
            resume <= 1'b0;
        end
        else begin
            // Save previous halted for C4
            halted_prev <= halted;

            // C3: haltreq + resumereq same cycle
            //     HALT WINS — check halt first
            if (haltreq) begin
                halt   <= 1'b1;
                resume <= 1'b0;
            end
            // C2: resumereq only if no haltreq
            else if (resumereq) begin
                resume <= 1'b1;
                halt   <= 1'b0;
            end
            else begin
                halt   <= 1'b0;
                resume <= 1'b0;
            end

            // Deassert resume after one cycle pulse
            // resume is a PULSE not a level signal
            if (resume) begin
                resume <= 1'b0;
            end
        end
    end

    // ─────────────────────────────────────
    // C1: allhalted ONLY after hart confirms
    // C2: allrunning ONLY after hart confirms
    // C4: detect spontaneous un-halt
    // These are combinational — instant update
    // ─────────────────────────────────────
    assign allhalted  = halted;
    assign allrunning = running;

endmodule