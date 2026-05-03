`timescale 1ns/1ps

module debug_module (
    input  logic        clk,
    input  logic        rst,

    // DMI Interface
    input  logic [1:0]  dmi_op,
    input  logic [6:0]  dmi_addr,
    input  logic [31:0] dmi_wdata,
    output logic [1:0]  dmi_resp,
    output logic [31:0] dmi_rdata,

    // Hart Interface
    output logic        halt,
    output logic        resume,
    input  logic        halted,
    input  logic        running,
    output logic        hart_req_valid,
    output logic        hart_req_write,
    output logic [15:0] hart_req_addr,
    output logic [31:0] hart_req_wdata,
    input  logic        hart_resp_valid,
    input  logic [31:0] hart_resp_rdata
);

    // ─────────────────────────────────────
    // Internal Wires
    // ─────────────────────────────────────
    logic        reg_wen;
    logic [6:0]  reg_addr;
    logic [31:0] reg_wdata;
    logic [31:0] reg_rdata;

    logic        haltreq;
    logic        resumereq;
    logic        dmactive;

    logic [31:0] command_reg;
    logic        cmd_valid;
    logic [31:0] data0_in;
    logic [31:0] data1;

    logic        busy;
    logic [2:0]  cmderr;
    logic [31:0] data0_out;

    logic        allhalted;
    logic        allrunning;

    // Convert active high rst to active low
    logic rst_n;
    assign rst_n = ~rst;

    // ─────────────────────────────────────
    // Module Instantiations
    // ─────────────────────────────────────

    dmi_slave u_dmi_slave (
        .clk      (clk),
        .rst      (rst),
        .dmi_op   (dmi_op),
        .dmi_addr (dmi_addr),
        .dmi_wdata(dmi_wdata),
        .dmi_resp (dmi_resp),
        .dmi_rdata(dmi_rdata),
        .reg_wen  (reg_wen),
        .reg_addr (reg_addr),
        .reg_wdata(reg_wdata),
        .reg_rdata(reg_rdata)
    );

    dm_regfile u_dm_regfile (
        .clk        (clk),
        .rst        (rst),
        .wen        (reg_wen),
        .addr       (reg_addr),
        .wdata      (reg_wdata),
        .rdata      (reg_rdata),
        .haltreq    (haltreq),
        .resumereq  (resumereq),
        .dmactive   (dmactive),
        .halted     (allhalted),
        .running    (allrunning),
        .command_reg(command_reg),
        .cmd_valid  (cmd_valid),
        .busy       (busy),
        .cmderr     (cmderr),
        .data0_in   (data0_in),
        .data1      (data1),
        .data0_out  (data0_out)
    );

    halt_resume_ctrl u_halt_resume (
        .clk       (clk),
        .rst       (rst),
        .dmactive  (dmactive),
        .haltreq   (haltreq),
        .resumereq (resumereq),
        .halt      (halt),
        .resume    (resume),
        .halted    (halted),
        .running   (running),
        .allhalted (allhalted),
        .allrunning(allrunning)
    );

    abstract_cmd_fsm u_abs_cmd_fsm (
        .clk             (clk),
        .rst_n           (rst_n),
        .cmd_valid       (cmd_valid),
        .command_reg     (command_reg),
        .data0_in        (data0_in),
        .busy            (busy),
        .cmderr          (cmderr),
        .data0_out       (data0_out),
        .hart_halted     (allhalted),
        .hart_req_valid  (hart_req_valid),
        .hart_req_write  (hart_req_write),
        .hart_req_addr   (hart_req_addr),
        .hart_req_wdata  (hart_req_wdata),
        .hart_resp_valid (hart_resp_valid),
        .hart_resp_rdata (hart_resp_rdata)
    );

endmodule