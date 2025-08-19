//SystemVerilog
module conditional_regfile #(
    parameter WIDTH = 32,
    parameter DEPTH = 16,
    parameter ADDR_WIDTH = $clog2(DEPTH)
)(
    input  wire                   clk,
    input  wire                   reset,
    
    // Write port with condition
    input  wire                   wr_en,
    input  wire [ADDR_WIDTH-1:0]  wr_addr,
    input  wire [WIDTH-1:0]       wr_data,
    input  wire [WIDTH-1:0]       wr_mask,      // Mask for conditional update
    input  wire                   wr_condition, // Only update if condition is true
    
    // Read port
    input  wire [ADDR_WIDTH-1:0]  rd_addr,
    output reg  [WIDTH-1:0]       rd_data
);
    // Register array
    reg [WIDTH-1:0] memory [0:DEPTH-1];
    
    // Pre-compute write condition and masked data
    wire write_valid = wr_en && wr_condition;
    wire [WIDTH-1:0] masked_data = wr_data & wr_mask;
    wire [WIDTH-1:0] masked_orig = ~wr_mask;
    
    // Registered read to improve timing
    always @(posedge clk) begin
        rd_data <= memory[rd_addr];
    end
    
    // Conditional write with masking
    integer i;
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                memory[i] <= {WIDTH{1'b0}};
            end
        end
        else if (write_valid) begin
            // Split the complex expression into simpler terms
            // Pre-compute the masked values and then combine
            memory[wr_addr] <= (memory[wr_addr] & masked_orig) | masked_data;
        end
    end
endmodule