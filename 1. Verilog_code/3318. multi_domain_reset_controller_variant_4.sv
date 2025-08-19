//SystemVerilog
// Top-level module: Multi-Domain Reset Controller
module multi_domain_reset_controller(
    input  wire clk,
    input  wire global_rst_n,
    input  wire por_n,
    input  wire ext_n,
    input  wire wdt_n,
    input  wire sw_n,
    output wire core_rst_n,
    output wire periph_rst_n,
    output wire mem_rst_n
);

    // Internal signal for aggregated async reset
    wire reset_active;
    // Internal signal for reset counter
    wire [1:0] reset_counter;

    // Reset Source Aggregator: Combines all reset sources into one active signal
    reset_source_aggregator u_reset_source_aggregator (
        .por_n     (por_n),
        .ext_n     (ext_n),
        .wdt_n     (wdt_n),
        .sw_n      (sw_n),
        .reset_active(reset_active)
    );

    // Reset Sequence Counter: Generates a counter based on reset conditions
    reset_sequence_counter u_reset_sequence_counter (
        .clk            (clk),
        .global_rst_n   (global_rst_n),
        .reset_active   (reset_active),
        .reset_counter  (reset_counter)
    );

    // Reset Output Generator: Decodes the counter into the three reset outputs
    reset_output_generator u_reset_output_generator (
        .reset_counter  (reset_counter),
        .core_rst_n     (core_rst_n),
        .periph_rst_n   (periph_rst_n),
        .mem_rst_n      (mem_rst_n)
    );

endmodule

//------------------------------------------------------------------------------
// Submodule: reset_source_aggregator
// Description: Aggregates all asynchronous reset sources into a single signal
//------------------------------------------------------------------------------
module reset_source_aggregator (
    input  wire por_n,
    input  wire ext_n,
    input  wire wdt_n,
    input  wire sw_n,
    output wire reset_active
);
    assign reset_active = ~(por_n & ext_n & wdt_n & sw_n);
endmodule

//------------------------------------------------------------------------------
// Submodule: reset_sequence_counter
// Description: Synchronous counter for reset sequencing based on reset activity
//------------------------------------------------------------------------------
module reset_sequence_counter (
    input  wire       clk,
    input  wire       global_rst_n,
    input  wire       reset_active,
    output reg [1:0]  reset_counter
);
    always @(posedge clk or negedge global_rst_n) begin
        if (!global_rst_n) begin
            reset_counter <= 2'b00;
        end else if (reset_active) begin
            reset_counter <= 2'b00;
        end else begin
            reset_counter <= (reset_counter[1] & reset_counter[0]) ? 2'b11 : reset_counter + 1'b1;
        end
    end
endmodule

//------------------------------------------------------------------------------
// Submodule: reset_output_generator
// Description: Decodes the reset_counter to generate domain-specific reset signals
//------------------------------------------------------------------------------
module reset_output_generator (
    input  wire [1:0] reset_counter,
    output wire       core_rst_n,
    output wire       periph_rst_n,
    output wire       mem_rst_n
);
    assign core_rst_n   = reset_counter[0] | reset_counter[1];
    assign periph_rst_n = reset_counter[1];
    assign mem_rst_n    = reset_counter[1] & reset_counter[0];
endmodule