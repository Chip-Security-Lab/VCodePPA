//SystemVerilog
// SystemVerilog - IEEE 1364-2005
// Top module - Enabled D Flip-Flop with optimized architecture
module d_ff_enable #(
    parameter DATA_WIDTH = 1
) (
    input  wire                  clock,    // System clock input
    input  wire                  enable,   // Enable signal
    input  wire [DATA_WIDTH-1:0] data_in,  // Data input
    output wire [DATA_WIDTH-1:0] data_out  // Data output
);
    // Direct implementation without submodules for critical path reduction
    reg [DATA_WIDTH-1:0] data_out_reg;
    
    // Combinational part pre-calculated
    wire valid_data = enable;
    wire [DATA_WIDTH-1:0] selected_data = data_in;
    
    // Sequential logic
    always @(posedge clock) begin
        if (valid_data) begin
            data_out_reg <= selected_data;
        end
    end
    
    // Output assignment
    assign data_out = data_out_reg;
    
endmodule

// Enable controller submodule - optimized for balance
module d_ff_enable_controller #(
    parameter DATA_WIDTH = 1
) (
    input  wire [DATA_WIDTH-1:0] data_in,   // Input data
    input  wire                  enable,    // Enable signal
    output wire [DATA_WIDTH-1:0] gated_data // Controlled data output
);
    // Direct assignment replaces procedural block
    // Reduced critical path by eliminating always block overhead
    assign gated_data = enable ? data_in : {DATA_WIDTH{1'bz}};
    
endmodule

// Storage element submodule with balanced paths
module d_ff_storage #(
    parameter DATA_WIDTH = 1
) (
    input  wire                  clock,      // Clock signal
    input  wire [DATA_WIDTH-1:0] gated_data, // Data input after gating
    output reg  [DATA_WIDTH-1:0] data_out    // Registered output
);
    // Pre-calculated validity check to reduce critical path
    wire valid_data = (^gated_data !== 1'bz);
    
    // Sequential logic with simplified condition
    always @(posedge clock) begin
        if (valid_data) begin
            data_out <= gated_data;
        end
    end
    
endmodule