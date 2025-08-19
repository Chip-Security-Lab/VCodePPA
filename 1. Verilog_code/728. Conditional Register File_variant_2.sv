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
    output wire [WIDTH-1:0]       rd_data
);
    // Register array
    reg [WIDTH-1:0] memory [0:DEPTH-1];
    
    // Combinational read
    assign rd_data = memory[rd_addr];
    
    // Combined write enable signal
    wire write_valid = wr_en & wr_condition;
    
    // Conditional write with masking
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset all memory locations using for loop
            integer j;
            for (j = 0; j < DEPTH; j = j + 1) begin
                memory[j] <= '0;  // Use SystemVerilog shorthand for zero
            end
        end
        else if (write_valid) begin
            // Directly write to memory using optimized boolean expression
            // Original: (memory[wr_addr] & ~wr_mask) | (wr_data & wr_mask)
            // This can be rewritten using multiplexer logic: choose wr_data or memory[wr_addr] based on mask
            memory[wr_addr] <= (wr_data & wr_mask) | (memory[wr_addr] & (~wr_mask));
        end
    end
endmodule