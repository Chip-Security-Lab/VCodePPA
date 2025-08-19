//SystemVerilog
module regfile_async #(
    parameter WORD_SIZE = 16,
    parameter ADDR_BITS = 4,
    parameter NUM_WORDS = 16
)(
    input clk,
    input write_en,
    input [ADDR_BITS-1:0] raddr,
    input [ADDR_BITS-1:0] waddr,
    input [WORD_SIZE-1:0] wdata,
    output reg [WORD_SIZE-1:0] rdata
);
    reg [WORD_SIZE-1:0] storage [0:NUM_WORDS-1];
    reg [ADDR_BITS-1:0] raddr_reg;

    // Combined always block for read address, write operation, and read logic
    always @(posedge clk) begin
        raddr_reg <= raddr; // Register read address to improve timing
        
        if (write_en) begin
            storage[waddr] <= wdata; // Write operation
        end
        
        rdata <= storage[raddr_reg]; // Read logic with pipeline stage
    end
endmodule