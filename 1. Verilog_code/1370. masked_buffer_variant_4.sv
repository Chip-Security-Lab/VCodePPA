//SystemVerilog
// Top-level module (IEEE 1364-2005)
module masked_buffer (
    input wire clk,
    input wire [15:0] data_in,
    input wire [15:0] mask,
    input wire write_en,
    output wire [15:0] data_out
);
    // Optimized direct implementation without separate submodules
    reg [15:0] data_reg;
    
    // Combinational logic - merge the operations from submodules
    wire [15:0] next_data = (data_in & mask) | (data_reg & ~mask);
    
    // Sequential logic
    always @(posedge clk) begin
        if (write_en)
            data_reg <= next_data;
    end
    
    // Output assignment
    assign data_out = data_reg;
    
endmodule