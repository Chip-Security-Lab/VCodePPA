//SystemVerilog
module diff_manchester_enc (
    input clk,
    input rst_n,
    input data_in,
    output reg encoded
);
    reg prev_bit_reg;

    wire xor_result;
    assign xor_result = prev_bit_reg ^ data_in;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_bit_reg <= 1'b0;
        end else begin
            prev_bit_reg <= xor_result;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            encoded <= 1'b0;
        end else begin
            encoded <= xor_result;
        end
    end

endmodule