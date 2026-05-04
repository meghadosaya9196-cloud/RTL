//==================================================================
// refresh_timer.sv
// Parameterised free-running interval counter that pulses
// refresh_due when the programmed interval is reached.
//==================================================================

module refresh_timer #(
    parameter int CNT_WIDTH = 32
)
(
    input  logic                 clk,
    input  logic                 rst_n,

    input  logic                 enable,

    input  logic [CNT_WIDTH-1:0] refresh_interval,

    output logic                 refresh_due,
    output logic [CNT_WIDTH-1:0] refresh_counter
);

    //--------------------------------------------------
    // Refresh Timer
    //--------------------------------------------------

    always_ff @(posedge clk or negedge rst_n)
    begin

        if (!rst_n)
        begin
            refresh_counter <= '0;
            refresh_due     <= 1'b0;
        end

        else
        begin

            // Default pulse low
            refresh_due <= 1'b0;

            // Timer active only when enabled
            if (enable)
            begin

                // Interval reached
                if (refresh_counter >= refresh_interval)
                begin
                    refresh_counter <= '0;
                    refresh_due     <= 1'b1;
                end

                else
                begin
                    refresh_counter <= refresh_counter + 1'b1;
                end

            end

            else
            begin
                refresh_counter <= '0;
            end

        end

    end

endmodule