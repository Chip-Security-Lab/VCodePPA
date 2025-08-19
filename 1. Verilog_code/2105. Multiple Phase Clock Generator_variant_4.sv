//SystemVerilog
// Top-level module: Multi-phase clock generator with hierarchical structure

module multi_phase_clk_gen(
    input  wire clk_in,
    input  wire reset,
    output wire clk_0,    // 0 degrees
    output wire clk_90,   // 90 degrees
    output wire clk_180,  // 180 degrees
    output wire clk_270   // 270 degrees
);

    // Internal phase counter signal
    wire [1:0] phase_counter;

    // Phase Counter Generator
    phase_counter_gen u_phase_counter_gen (
        .clk_in        (clk_in),
        .reset         (reset),
        .phase_counter (phase_counter)
    );

    // Phase Output Generator
    phase_output_gen u_phase_output_gen (
        .clk_in        (clk_in),
        .reset         (reset),
        .phase_counter (phase_counter),
        .clk_0         (clk_0),
        .clk_90        (clk_90),
        .clk_180       (clk_180),
        .clk_270       (clk_270)
    );

endmodule

// ----------------------------------------------------------------------
// Phase Counter Generator
// Generates a 2-bit phase counter for the multi-phase clock generator.
// ----------------------------------------------------------------------
module phase_counter_gen(
    input  wire       clk_in,
    input  wire       reset,
    output reg  [1:0] phase_counter
);
    always @(posedge clk_in or posedge reset) begin
        if (reset) begin
            phase_counter <= 2'b00;
        end else begin
            phase_counter <= phase_counter + 2'b01;
        end
    end
endmodule

// ----------------------------------------------------------------------
// Phase Output Generator
// Decodes the phase counter to generate four phase-shifted clock signals.
// ----------------------------------------------------------------------
module phase_output_gen(
    input  wire       clk_in,
    input  wire       reset,
    input  wire [1:0] phase_counter,
    output reg        clk_0,
    output reg        clk_90,
    output reg        clk_180,
    output reg        clk_270
);
    always @(posedge clk_in or posedge reset) begin
        if (reset) begin
            clk_0   <= 1'b1;
            clk_90  <= 1'b0;
            clk_180 <= 1'b0;
            clk_270 <= 1'b0;
        end else begin
            clk_0   <= (phase_counter == 2'b01) ? 1'b0 : (phase_counter == 2'b00);
            clk_90  <= (phase_counter == 2'b10) ? 1'b0 : (phase_counter == 2'b01);
            clk_180 <= (phase_counter == 2'b11) ? 1'b0 : (phase_counter == 2'b10);
            clk_270 <= (phase_counter == 2'b00) ? 1'b0 : (phase_counter == 2'b11);
        end
    end
endmodule