//SystemVerilog
module sync_decoder_with_reset #(
    parameter ADDR_BITS = 2,
    parameter OUT_BITS = 4
)(
    input wire clk,
    input wire rst,
    input wire [ADDR_BITS-1:0] addr,
    output reg [OUT_BITS-1:0] decode
);

    // 输入寄存器级
    reg [ADDR_BITS-1:0] addr_reg;
    
    // 解码计算级
    wire [OUT_BITS-1:0] decode_calc;
    assign decode_calc = (1 << addr_reg);
    
    // 输出寄存器级
    always @(posedge clk) begin
        if (rst) begin
            addr_reg <= {ADDR_BITS{1'b0}};
            decode <= {OUT_BITS{1'b0}};
        end else begin
            addr_reg <= addr;
            decode <= decode_calc;
        end
    end

endmodule