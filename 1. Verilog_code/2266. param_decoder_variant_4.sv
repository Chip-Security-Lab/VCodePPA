//SystemVerilog
module param_decoder #(
    parameter ADDR_WIDTH = 4,
    parameter OUT_WIDTH = 16
)(
    input [ADDR_WIDTH-1:0] address,
    input enable,
    output reg [OUT_WIDTH-1:0] select
);
    integer i;
    reg [OUT_WIDTH-1:0] barrel_out;
    
    // 桶形移位器实现
    always @(*) begin
        barrel_out = {{(OUT_WIDTH-1){1'b0}}, 1'b1};
        
        // 多级移位结构
        for (i = 0; i < ADDR_WIDTH; i = i + 1) begin
            if (address[i])
                barrel_out = (barrel_out << (1 << i));
        end
        
        // 输出选择
        if (enable)
            select = barrel_out;
        else
            select = {OUT_WIDTH{1'b0}};
    end
endmodule