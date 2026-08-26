`timescale 1ns/1ps

module top_cov_tb;

    logic [31:0] data_in;
    logic [31:0] data_out;
    logic        clk;
    logic        rst;

    //========================================================
    // DUT
    //========================================================

    top dut (
        .data_in  (data_in),
        .data_out (data_out),
        .clk      (clk),
        .rst      (rst)
    );


    //========================================================
    // CLOCK
    // Professor's top_tb uses #0.5
    // Therefore clock period = 1 ns
    //========================================================

    initial begin
        clk = 1'b0;
        forever #0.5 clk = ~clk;
    end


    //========================================================
    // FUNCTIONAL COVERAGE
    //========================================================

    covergroup serdes_cg @(posedge clk);

        option.per_instance = 1;


        // ---------------------------------------------------
        // RESET
        // ---------------------------------------------------

        cp_reset : coverpoint rst {
            bins reset_active   = {1'b1};
            bins reset_inactive = {1'b0};
        }


        // ---------------------------------------------------
        // 32-BIT DATA PATTERNS
        // ---------------------------------------------------

        cp_data : coverpoint data_in {

            bins all_zero = {32'h00000000};
            bins all_one  = {32'hFFFFFFFF};

            bins aa_pattern = {32'hAAAAAAAA};
            bins 55_pattern = {32'h55555555};

            bins a5_pattern = {32'hA5A5A5A5};
            bins 5a_pattern = {32'h5A5A5A5A};

            bins other = default;
        }


        // ---------------------------------------------------
        // LANE 0 : data[7:0]
        // ---------------------------------------------------

        cp_lane0 : coverpoint data_in[7:0] {

            bins zero = {8'h00};
            bins ones = {8'hFF};
            bins aa   = {8'hAA};
            bins 55   = {8'h55};

            bins low  = {[8'h01:8'h3F]};
            bins mid  = {[8'h40:8'hBF]};
            bins high = {[8'hC0:8'hFE]};
        }


        // ---------------------------------------------------
        // LANE 1 : data[15:8]
        // ---------------------------------------------------

        cp_lane1 : coverpoint data_in[15:8] {

            bins zero = {8'h00};
            bins ones = {8'hFF};
            bins aa   = {8'hAA};
            bins 55   = {8'h55};

            bins low  = {[8'h01:8'h3F]};
            bins mid  = {[8'h40:8'hBF]};
            bins high = {[8'hC0:8'hFE]};
        }


        // ---------------------------------------------------
        // LANE 2 : data[23:16]
        // ---------------------------------------------------

        cp_lane2 : coverpoint data_in[23:16] {

            bins zero = {8'h00};
            bins ones = {8'hFF};
            bins aa   = {8'hAA};
            bins 55   = {8'h55};

            bins low  = {[8'h01:8'h3F]};
            bins mid  = {[8'h40:8'hBF]};
            bins high = {[8'hC0:8'hFE]};
        }


        // ---------------------------------------------------
        // LANE 3 : data[31:24]
        // ---------------------------------------------------

        cp_lane3 : coverpoint data_in[31:24] {

            bins zero = {8'h00};
            bins ones = {8'hFF};
            bins aa   = {8'hAA};
            bins 55   = {8'h55};

            bins low  = {[8'h01:8'h3F]};
            bins mid  = {[8'h40:8'hBF]};
            bins high = {[8'hC0:8'hFE]};
        }


        // ---------------------------------------------------
        // TRANSMITTER FSM
        //
        // s_state is inside SerDes
        // S0 = 000
        // S1 = 001
        // S2 = 010
        // S3 = 011
        // S4 = 100
        // ---------------------------------------------------

        cp_tx_state : coverpoint dut.S1.s_state {

            bins S0 = {3'b000};
            bins S1 = {3'b001};
            bins S2 = {3'b010};
            bins S3 = {3'b011};
            bins S4 = {3'b100};
        }


        // ---------------------------------------------------
        // RECEIVER FSM
        //
        // P0 = 0101
        // P1 = 0110
        // P2 = 0111
        // P3 = 1000
        // ---------------------------------------------------

        cp_rx_state : coverpoint dut.S1.d_state {

            bins P0 = {4'b0101};
            bins P1 = {4'b0110};
            bins P2 = {4'b0111};
            bins P3 = {4'b1000};
        }


        // ---------------------------------------------------
        // ENCODER ENABLE
        // ---------------------------------------------------

        cp_encoder_enable : coverpoint dut.S1.en_en {

            bins disabled = {1'b0};
            bins enabled  = {1'b1};
        }


        // ---------------------------------------------------
        // PISO LOAD
        // ---------------------------------------------------

        cp_piso_load : coverpoint dut.S1.p_en {

            bins disabled = {1'b0};
            bins enabled  = {1'b1};
        }


        // ---------------------------------------------------
        // SIPO CONTROL
        // ---------------------------------------------------

        cp_sipo_control : coverpoint dut.S1.s_en {

            bins disabled = {1'b0};
            bins enabled  = {1'b1};
        }


        // ---------------------------------------------------
        // DECODER ENABLE
        // ---------------------------------------------------

        cp_decoder_enable : coverpoint dut.S1.de_en {

            bins disabled = {1'b0};
            bins enabled  = {1'b1};
        }


        // ---------------------------------------------------
        // START SIGNAL
        // ---------------------------------------------------

        cp_start : coverpoint dut.S1.start_o {

            bins idle  = {1'b0};
            bins start = {1'b1};
        }

    endgroup


    serdes_cg cg = new();


    //========================================================
    // SCOREBOARD
    //========================================================

    integer pass_count = 0;
    integer fail_count = 0;

    task automatic send_and_check(input logic [31:0] expected_data);

        begin

            // Apply new transaction
            data_in = expected_data;

            // Wait for current transmission to be idle
            wait (dut.S1.start_o === 1'b0);

            // Wait for this transaction's start pulse
            wait (dut.S1.start_o === 1'b1);

            $display("----------------------------------------");
            $display("Transaction started");
            $display("Expected data = %08h", expected_data);

            // Wait until receiver reaches P3.
            //
            // Decoder is enabled in P2 and the output is
            // available after that clock event.
            wait (dut.S1.d_state === 4'b1000);

            @(negedge clk);

            if (data_out === expected_data) begin

                pass_count++;

                $display("PASS");
                $display("data_in  = %08h", expected_data);
                $display("data_out = %08h", data_out);

            end
            else begin

                fail_count++;

                $display("FAIL");
                $display("Expected = %08h", expected_data);
                $display("Actual   = %08h", data_out);

            end

        end

    endtask


    //========================================================
    // ASSERTIONS
    //========================================================

    // Reset should put TX FSM in S0.
    property reset_tx_state;
        @(posedge clk)
        rst |-> (dut.S1.s_state == 3'b000);
    endproperty

    assert property(reset_tx_state)
        else $error("TX FSM is not in S0 during reset");


    // Reset should put RX FSM in P0.
    property reset_rx_state;
        @(posedge clk)
        rst |-> (dut.S1.d_state == 4'b0101);
    endproperty

    assert property(reset_rx_state)
        else $error("RX FSM is not in P0 during reset");


    // PISO load should only happen when p_en is asserted.
    // This is an observation assertion, not a datapath assertion.
    property start_requires_piso_load;
        @(posedge clk)
        dut.S1.start_o |-> dut.S1.p_en;
    endproperty

    assert property(start_requires_piso_load)
        else $error("start_o asserted without p_en");


    //========================================================
    // TEST SEQUENCE
    //========================================================

    initial begin

        rst     = 1'b1;
        data_in = 32'h00000000;

        // Reset
        #2;
        rst = 1'b0;

        // ---------------------------------------------------
        // Directed patterns
        // ---------------------------------------------------

        send_and_check(32'hAAAAAAAA);

        send_and_check(32'h55555555);

        send_and_check(32'hFFFFFFFF);

        send_and_check(32'h00000000);

        send_and_check(32'hA5A5A5A5);

        send_and_check(32'h5A5A5A5A);

        send_and_check(32'h12345678);

        send_and_check(32'h87654321);


        // ---------------------------------------------------
        // Exercise each lane with different values
        // ---------------------------------------------------

        send_and_check(32'h000000FF);

        send_and_check(32'h0000FF00);

        send_and_check(32'h00FF0000);

        send_and_check(32'hFF000000);


        // ---------------------------------------------------
        // Random transactions
        // ---------------------------------------------------

        repeat (50) begin

            send_and_check($urandom);

        end


        // ---------------------------------------------------
        // Coverage summary
        // ---------------------------------------------------

        $display("");
        $display("========================================");
        $display("       SERDES TEST SUMMARY");
        $display("========================================");

        $display("PASS COUNT = %0d", pass_count);
        $display("FAIL COUNT = %0d", fail_count);

        $display("Functional Coverage = %0.2f%%",
                 cg.get_inst_coverage());

        $display("========================================");


        #10;

        $finish;

    end


    //========================================================
    // WAVEFORM
    //========================================================

    initial begin

        $dumpfile("serdes_cov.vcd");
        $dumpvars(0, top_cov_tb);

    end

endmodule
