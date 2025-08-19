module pipelined_demux (
    input wire clk,                       // System clock
    input wire data_in,                   // Input data
    input wire [1:0] addr,                // Address selection
    output reg [3:0] demux_out            // Output channels
);
    reg data_reg;                         // Pipeline register for data
    reg [1:0] addr_reg;                   // Pipeline register for address
    
    always @(posedge clk) begin
        // First pipeline stage
        data_reg <= data_in;
        addr_reg <= addr;
        
        // Second pipeline stage
        demux_out <= 4'b0;
        demux_out[addr_reg] <= data_reg;
    end
endmodule