//SystemVerilog
module hash_table #(parameter DW=8, TABLE_SIZE=16) (
    input clk,
    input valid,
    input [DW-1:0] key,
    output reg [DW-1:0] hash
);
    // Combinational logic: hash_index and hash_val
    wire [3:0] hash_index_comb;
    wire [3:0] hash_val_comb;

    assign hash_index_comb = key[7:4] ^ key[3:0];
    assign hash_val_comb = ( (key[3:0]<<3) + (key[3:0]<<2) + (key[3:0]<<1) ) & 4'hF;

    // Forward register retiming: move register after combinational logic
    reg [3:0] hash_val_reg;
    always @(posedge clk) begin
        if(valid)
            hash_val_reg <= hash_val_comb;
    end

    always @(posedge clk) begin
        if(valid)
            hash <= { {(DW-4){1'b0}}, hash_val_reg };
    end
endmodule