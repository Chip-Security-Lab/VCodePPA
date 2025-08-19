//SystemVerilog
module dram_error_inject #(
    parameter ERROR_MASK = 8'hFF
)(
    input clk,
    input rst_n,
    input enable,
    input [63:0] data_in,
    output reg [63:0] data_out
);

    reg [63:0] data_in_reg;
    reg enable_reg;
    wire [63:0] error_mask = {8{ERROR_MASK}};
    wire [63:0] xor_result = data_in_reg ^ error_mask;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= 64'h0;
            enable_reg <= 1'b0;
            data_out <= 64'h0;
        end else begin
            data_in_reg <= data_in;
            enable_reg <= enable;
            data_out <= enable_reg ? xor_result : data_in_reg;
        end
    end

endmodule