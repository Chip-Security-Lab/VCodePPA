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
    
    always @(posedge clk) begin
        if (write_en) begin
            storage[waddr] <= wdata;
        end
    end
    
    always @* begin
        rdata = storage[raddr]; // Using combinational logic for read data
    end
endmodule