module dmi_slave (
    input  logic        clk,
    input  logic        rst,
    input  logic [1:0]  dmi_op,
    input  logic [6:0]  dmi_addr,
    input  logic [31:0] dmi_wdata,
    output logic [1:0]  dmi_resp,
    output logic [31:0] dmi_rdata,
    output logic        reg_wen,
    output logic [6:0]  reg_addr,
    output logic [31:0] reg_wdata,
    input  logic [31:0] reg_rdata
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            dmi_resp  <= 2'b00;
            dmi_rdata <= 32'h0;
            reg_wen   <= 1'b0;
            reg_addr  <= 7'h0;
            reg_wdata <= 32'h0;
        end
        else begin
            reg_wen <= 1'b0;  // default clear

            case (dmi_op)
                2'b01: begin  // READ
                    reg_addr  <= dmi_addr;
                    dmi_rdata <= reg_rdata;
                    dmi_resp  <= 2'b00;
                end

                2'b10: begin  // WRITE
                    reg_wen   <= 1'b1;
                    reg_addr  <= dmi_addr;
                    reg_wdata <= dmi_wdata;
                    dmi_resp  <= 2'b00;
                end

                default: begin  // NOP
                    dmi_resp  <= 2'b00;
                end

            endcase
        end
    end

endmodule