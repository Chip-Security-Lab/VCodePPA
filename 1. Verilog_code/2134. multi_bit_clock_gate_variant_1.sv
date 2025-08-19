//SystemVerilog
////////////////////////////////////////////////////////////////////////////////////
// Module Name: multi_bit_clock_gate
// Description: Top module for multi-bit clock gating with improved architecture
//              Uses single-bit clock gate cells for better power management
//              Hierarchical architecture with separate control and distribution logic
////////////////////////////////////////////////////////////////////////////////////
module multi_bit_clock_gate #(
    parameter WIDTH = 4
) (
    input  wire clk_in,
    input  wire [WIDTH-1:0] enable_vector,
    output wire [WIDTH-1:0] clk_out
);
    // Clock control signals
    wire gated_clock;
    wire [WIDTH-1:0] final_enable;
    
    // Clock control unit for centralized clock management
    clock_control_unit u_clock_control (
        .clk_in(clk_in),
        .enable_vector(enable_vector),
        .final_enable(final_enable)
    );
    
    // Clock distribution network for improved fan-out handling
    clock_distribution_network #(
        .WIDTH(WIDTH)
    ) u_clock_dist (
        .clk_in(clk_in),
        .final_enable(final_enable),
        .clk_out(clk_out)
    );
endmodule

////////////////////////////////////////////////////////////////////////////////////
// Module Name: clock_control_unit
// Description: Manages the enable signals with proper synchronization
//              Handles enable signal conditioning to prevent glitches
////////////////////////////////////////////////////////////////////////////////////
module clock_control_unit (
    input  wire clk_in,
    input  wire [WIDTH-1:0] enable_vector,
    output reg  [WIDTH-1:0] final_enable
);
    parameter WIDTH = 4;
    
    // Pre-process enable signals to prevent glitches and optimize for power
    always @(posedge clk_in) begin
        final_enable <= enable_vector;
    end
endmodule

////////////////////////////////////////////////////////////////////////////////////
// Module Name: clock_distribution_network
// Description: Distributes the clock to multiple endpoints
//              Manages balanced clock tree for minimal skew
////////////////////////////////////////////////////////////////////////////////////
module clock_distribution_network #(
    parameter WIDTH = 4
) (
    input  wire clk_in,
    input  wire [WIDTH-1:0] final_enable,
    output wire [WIDTH-1:0] clk_out
);
    // Clock buffer to improve drive strength for multiple outputs
    wire buffered_clk;
    
    // Buffer the input clock to reduce load on source
    clock_buffer u_buffer (
        .clk_in(clk_in),
        .buffered_clk(buffered_clk)
    );
    
    // Instantiate individual clock gate cells for each bit
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gate_gen
            clock_gate_cell u_clock_gate (
                .clk_in(buffered_clk),
                .enable(final_enable[i]),
                .clk_out(clk_out[i])
            );
        end
    endgenerate
endmodule

////////////////////////////////////////////////////////////////////////////////////
// Module Name: clock_buffer
// Description: Simple clock buffer to improve driving capability
//              Reduces load on the source clock
////////////////////////////////////////////////////////////////////////////////////
module clock_buffer (
    input  wire clk_in,
    output wire buffered_clk
);
    // Non-inverting buffer
    assign buffered_clk = clk_in;
endmodule

////////////////////////////////////////////////////////////////////////////////////
// Module Name: clock_gate_cell
// Description: Optimized single-bit clock gating cell
//              Implements glitch-free clock gating for a single clock bit
////////////////////////////////////////////////////////////////////////////////////
module clock_gate_cell (
    input  wire clk_in,
    input  wire enable,
    output wire clk_out
);
    // Standard clock gating implementation with latch-based architecture
    // This improves glitch immunity compared to simple AND gate
    reg latch_enable;
    
    // Latch enable signal on negative edge to prevent glitches
    always @(negedge clk_in) begin
        latch_enable <= enable;
    end
    
    // Implement clock gating with latched enable for glitch-free operation
    assign clk_out = clk_in & latch_enable;
endmodule