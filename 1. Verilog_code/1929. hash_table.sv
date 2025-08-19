module hash_table #(parameter DW=8, TABLE_SIZE=16) (
    input clk, valid,
    input [DW-1:0] key,
    output reg [DW-1:0] hash
);
    wire [3:0] hash_index = key[7:4] ^ key[3:0];
    
    always @(posedge clk) begin
        if(valid) hash <= (key * 8'h9E) % TABLE_SIZE;
    end
endmodule
