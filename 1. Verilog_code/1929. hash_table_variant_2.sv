//SystemVerilog
module hash_table #(parameter DW=8, TABLE_SIZE=16) (
    input clk,
    input valid,
    input [DW-1:0] key,
    output reg [DW-1:0] hash
);
    wire [3:0] hash_index;
    wire [DW+7:0] mul_result;
    wire [3:0] table_size_minus_1;
    wire [3:0] subtrahend_wire;
    wire       subtract_enable_wire;
    wire [3:0] inv_subtrahend_wire;
    wire [4:0] adder_input_wire;
    wire       carry_in_wire;
    wire [4:0] adder_output_wire;
    wire [3:0] mod_result_wire;

    assign hash_index = key[7:4] ^ key[3:0];
    assign mul_result = key * 8'h9E;
    assign table_size_minus_1 = TABLE_SIZE - 1;

    // Expanded conditional assignments
    assign subtract_enable_wire = (mul_result[3:0] >= TABLE_SIZE) ? 1'b1 : 1'b0;
    assign subtrahend_wire = TABLE_SIZE[3:0];

    // Replacing ternary operator with if-else structure
    reg [3:0] inv_subtrahend_reg;
    always @(*) begin
        if (subtract_enable_wire) begin
            inv_subtrahend_reg = ~subtrahend_wire;
        end else begin
            inv_subtrahend_reg = subtrahend_wire;
        end
    end
    assign inv_subtrahend_wire = inv_subtrahend_reg;

    // Replacing ternary operator for carry_in_wire
    reg carry_in_reg;
    always @(*) begin
        if (subtract_enable_wire) begin
            carry_in_reg = 1'b1;
        end else begin
            carry_in_reg = 1'b0;
        end
    end
    assign carry_in_wire = carry_in_reg;

    assign adder_input_wire = {1'b0, mul_result[3:0]} + {1'b0, inv_subtrahend_wire} + carry_in_wire;
    assign mod_result_wire = adder_input_wire[3:0];

    reg [3:0] mod_result_reg;
    always @(posedge clk) begin
        if(valid)
            mod_result_reg <= mod_result_wire;
    end

    always @(posedge clk) begin
        if(valid)
            hash <= { {(DW-4){1'b0}}, mod_result_reg };
    end
endmodule