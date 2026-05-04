module hart_stub (
    input  logic        clk,
    input  logic        rst,
    input  logic        halt_req,
    input  logic        resume_req,
    output logic        halted,
    output logic        running,
    input  logic        reg_req,
    input  logic        reg_write,
    input  logic [15:0] regno,
    input  logic [31:0] write_data,
    output logic        reg_ack,
    output logic [31:0] read_data
);

    // GPR array
    logic [31:0] gpr [0:31];

    // CSR registers
    logic [31:0] mstatus;
    logic [31:0] mtvec;
    logic [31:0] mepc;
    logic [31:0] mcause;

    // Internal delayed request (for ack timing)
    logic reg_req_d;

    // ---------------------------------------
    // Halt / Resume Logic
    // ---------------------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            halted  <= 1'b0;
            running <= 1'b1;
        end
        else if (halt_req) begin
            halted  <= 1'b1;
            running <= 1'b0;
        end
        else if (resume_req) begin
            halted  <= 1'b0;
            running <= 1'b1;
        end
    end

    // ---------------------------------------
    // CSR + GPR WRITE (with reset)
    // ---------------------------------------
    integer i;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                gpr[i] <= 32'h0;

            mstatus <= 32'h0;
            mtvec   <= 32'h0;
            mepc    <= 32'h0;
            mcause  <= 32'h0;
        end
        else if (reg_req && reg_write) begin
            if (regno >= 16'h1000 && regno <= 16'h101F)
                gpr[regno - 16'h1000] <= write_data;
            else begin
                case (regno)
                    16'h0300: mstatus <= write_data;
                    16'h0305: mtvec   <= write_data;
                    16'h0341: mepc    <= write_data;
                    16'h0342: mcause  <= write_data;
                    default: ;
                endcase
            end
        end
    end

    // ---------------------------------------
    // READ path (data prepared BEFORE ack)
    // ---------------------------------------
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        reg_ack   <= 1'b0;
        read_data <= 32'h0;
    end else begin
        reg_ack <= reg_req;   // ack comes exactly 1 cycle after req

        if (reg_req && !reg_write) begin
            if (regno >= 16'h1000 && regno <= 16'h101F)
                read_data <= gpr[regno - 16'h1000];
            else begin
                case (regno)
                    16'h0300: read_data <= mstatus;
                    16'h0305: read_data <= mtvec;
                    16'h0341: read_data <= mepc;
                    16'h0342: read_data <= mcause;
                    default:  read_data <= 32'h0;
                endcase
            end
        end
    end
end

    // ---------------------------------------
    // ACK generation (1-cycle delayed)
    // ---------------------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_req_d <= 1'b0;
            reg_ack   <= 1'b0;
        end else begin
            reg_req_d <= reg_req;
            reg_ack   <= reg_req_d;  // delayed ack
        end
    end

endmodule