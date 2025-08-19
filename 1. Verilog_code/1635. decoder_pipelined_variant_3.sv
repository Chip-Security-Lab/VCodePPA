//SystemVerilog
module decoder_pipelined (
    input clk, en,
    input [5:0] addr,
    output [15:0] sel_reg
);
    wire [15:0] sel_comb;
    wire [3:0] addr_high;
    wire [1:0] addr_low;
    wire [3:0] decode_high;
    wire [3:0] decode_low;
    
    assign addr_high = addr[5:2];
    assign addr_low = addr[1:0];
    
    // Decode high bits
    assign decode_high = (addr_high == 4'b0000) ? 4'b0001 :
                        (addr_high == 4'b0001) ? 4'b0010 :
                        (addr_high == 4'b0010) ? 4'b0100 :
                        (addr_high == 4'b0011) ? 4'b1000 : 4'b0000;
                        
    // Decode low bits                        
    assign decode_low = (addr_low == 2'b00) ? 4'b0001 :
                       (addr_low == 2'b01) ? 4'b0010 :
                       (addr_low == 2'b10) ? 4'b0100 :
                       (addr_low == 2'b11) ? 4'b1000 : 4'b0000;
                       
    // Combine results
    assign sel_comb = en ? {decode_high, decode_low} : 16'b0;
    
    // Register output
    reg [15:0] sel_reg_r;
    always @(posedge clk) begin
        sel_reg_r <= sel_comb;
    end
    
    assign sel_reg = sel_reg_r;

endmodule