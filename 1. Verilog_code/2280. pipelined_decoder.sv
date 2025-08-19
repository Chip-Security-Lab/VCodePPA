module pipelined_decoder(
    input clk,
    input [3:0] addr_in,
    output reg [15:0] decode_out
);
    reg [3:0] addr_stage1;
    
    always @(posedge clk) begin
        // Pipeline stage 1: latch the address
        addr_stage1 <= addr_in;
        
        // Pipeline stage 2: perform decoding
        decode_out <= (16'b1 << addr_stage1);
    end
endmodule