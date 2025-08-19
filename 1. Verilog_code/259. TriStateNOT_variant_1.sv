//SystemVerilog
// Top level module
module TriStateNOT #(
    parameter WIDTH = 4  // Parameterized bit width
)(
    input wire clk,          // Clock signal (added)
    input wire rst_n,        // Reset signal (added)
    input wire oe,           // Output enable
    input wire [WIDTH-1:0] in,
    output wire [WIDTH-1:0] out
);
    // Internal pipeline signals
    reg [WIDTH-1:0] in_registered;
    wire [WIDTH-1:0] inverted_signal;
    reg [WIDTH-1:0] inverted_registered;
    reg oe_registered;
    
    // Input registration stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_registered <= {WIDTH{1'b0}};
            oe_registered <= 1'b0;
        end else begin
            in_registered <= in;
            oe_registered <= oe;
        end
    end
    
    // Instance of inverter core
    InverterCore #(
        .WIDTH(WIDTH)
    ) inverter_inst (
        .in(in_registered),
        .inverted_out(inverted_signal)
    );
    
    // Middle pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            inverted_registered <= {WIDTH{1'b0}};
        end else begin
            inverted_registered <= inverted_signal;
        end
    end
    
    // Instance of tri-state buffer
    TriStateBuffer #(
        .WIDTH(WIDTH)
    ) tri_state_inst (
        .oe(oe_registered),
        .in(inverted_registered),
        .out(out)
    );
    
endmodule

// Inverter logic core with optimized path
module InverterCore #(
    parameter WIDTH = 4
)(
    input wire [WIDTH-1:0] in,
    output wire [WIDTH-1:0] inverted_out
);
    // Pure inverter logic with width-based optimization
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : inverter_gen
            assign inverted_out[i] = ~in[i];
        end
    endgenerate
endmodule

// Tri-state buffer module with improved structure
module TriStateBuffer #(
    parameter WIDTH = 4
)(
    input wire oe,                    // Output enable
    input wire [WIDTH-1:0] in,
    output wire [WIDTH-1:0] out
);
    // Tri-state buffer implementation with explicit bit-selection
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : tri_buf_gen
            assign out[i] = oe ? in[i] : 1'bz;
        end
    endgenerate
endmodule