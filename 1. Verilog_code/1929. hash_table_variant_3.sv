//SystemVerilog
// Top-level hash_table module with hierarchical submodules
module hash_table #(parameter DW=8, TABLE_SIZE=16) (
    input wire clk,
    input wire valid,
    input wire [DW-1:0] key,
    output reg [DW-1:0] hash
);

    wire [3:0] hash_index;
    reg [DW-1:0] hash_value_reg;
    wire [DW+7:0] mult_result;

    // Hash index calculation submodule
    hash_index_calc #(.DW(DW)) u_hash_index_calc (
        .key_in(key),
        .index_out(hash_index)
    );

    assign mult_result = key * 8'h9E;

    // Combined sequential logic for hash value and output
    always @(posedge clk) begin
        if (valid) begin
            hash_value_reg <= mult_result % TABLE_SIZE;
            hash <= mult_result % TABLE_SIZE;
        end
    end

endmodule

// -----------------------------------------------------------------------------
// Submodule: hash_index_calc
// Purpose:   Calculate a 4-bit hash index from the input key
// -----------------------------------------------------------------------------
module hash_index_calc #(parameter DW=8) (
    input  wire [DW-1:0] key_in,
    output wire [3:0]    index_out
);
    assign index_out = key_in[7:4] ^ key_in[3:0];
endmodule