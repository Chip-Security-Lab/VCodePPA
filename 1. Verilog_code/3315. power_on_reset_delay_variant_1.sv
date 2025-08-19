//SystemVerilog
// SystemVerilog
// Top-level module: Power-on Reset Delay with Hierarchical Structure
module power_on_reset_delay #(
    parameter DELAY_COUNT = 16'd1000
)(
    input  wire clk,
    input  wire external_reset_n,
    output reg  reset_n
);

    // Internal signals for submodule connections
    wire        counter_done;
    wire        power_stable;

    // Counter Submodule: Handles delay counting after external reset deassertion
    power_on_reset_counter #(
        .DELAY_COUNT(DELAY_COUNT)
    ) u_power_on_reset_counter (
        .clk                (clk),
        .external_reset_n   (external_reset_n),
        .counter_done       (counter_done)
    );

    // Power Stable Pipeline Register Submodule
    power_stable_pipeline u_power_stable_pipeline (
        .clk                (clk),
        .external_reset_n   (external_reset_n),
        .counter_done       (counter_done),
        .power_stable       (power_stable)
    );

    // Reset Output Pipeline Register Submodule
    reset_output_pipeline u_reset_output_pipeline (
        .clk                (clk),
        .external_reset_n   (external_reset_n),
        .power_stable       (power_stable),
        .reset_n            (reset_n)
    );

endmodule

// -----------------------------------------------------------------------------
// Submodule: power_on_reset_counter
// Function: Counts clock cycles after external reset is deasserted. Outputs
//           a done signal when the count reaches DELAY_COUNT.
// -----------------------------------------------------------------------------
module power_on_reset_counter #(
    parameter DELAY_COUNT = 16'd1000
)(
    input  wire clk,
    input  wire external_reset_n,
    output reg  counter_done
);

    reg [15:0] delay_counter;

    always @(posedge clk or negedge external_reset_n) begin
        if (!external_reset_n) begin
            delay_counter <= 16'd0;
            counter_done  <= 1'b0;
        end else begin
            if (!counter_done) begin
                if (delay_counter < DELAY_COUNT - 16'd1) begin
                    delay_counter <= delay_counter + 16'd1;
                    counter_done  <= 1'b0;
                end else begin
                    delay_counter <= delay_counter; // Hold value
                    counter_done  <= 1'b1;
                end
            end
        end
    end

endmodule

// -----------------------------------------------------------------------------
// Submodule: power_stable_pipeline
// Function: Pipeline register to hold the power stable (counter_done) signal.
// -----------------------------------------------------------------------------
module power_stable_pipeline (
    input  wire clk,
    input  wire external_reset_n,
    input  wire counter_done,
    output reg  power_stable
);

    always @(posedge clk or negedge external_reset_n) begin
        if (!external_reset_n) begin
            power_stable <= 1'b0;
        end else begin
            power_stable <= counter_done;
        end
    end

endmodule

// -----------------------------------------------------------------------------
// Submodule: reset_output_pipeline
// Function: Final pipeline register to align the output reset_n signal.
// -----------------------------------------------------------------------------
module reset_output_pipeline (
    input  wire clk,
    input  wire external_reset_n,
    input  wire power_stable,
    output reg  reset_n
);

    always @(posedge clk or negedge external_reset_n) begin
        if (!external_reset_n) begin
            reset_n <= 1'b0;
        end else begin
            reset_n <= power_stable;
        end
    end

endmodule