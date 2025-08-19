//SystemVerilog
// SystemVerilog
module jittered_clock_rng (
    input wire main_clk,
    input wire reset,
    input wire [7:0] jitter_value,
    output reg [15:0] random_out
);

    reg [7:0] counter;
    reg capture_bit;

    wire counter_eq_jitter = ~( |(counter ^ jitter_value) ); // counter == jitter_value
    wire feedback_bit = random_out[15] ^ counter[0];

    // Counter logic: Handles counter update and reset
    // -----------------------------------------------
    always @(posedge main_clk) begin
        if (reset) begin
            counter <= 8'h01;
        end else begin
            counter <= counter + 8'b1;
        end
    end

    // Capture bit logic: Toggles capture_bit when counter matches jitter_value, or resets
    // ----------------------------------------------------------------------------------
    always @(posedge main_clk) begin
        if (reset) begin
            capture_bit <= 1'b0;
        end else if (counter_eq_jitter) begin
            capture_bit <= ~capture_bit;
        end
    end

    // Random output logic: Shifts in feedback bit when capture_bit is high, or resets
    // -------------------------------------------------------------------------------
    always @(posedge main_clk) begin
        if (reset) begin
            random_out <= 16'h1234;
        end else if (capture_bit) begin
            random_out <= {random_out[14:0], feedback_bit};
        end
    end

endmodule