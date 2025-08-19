//SystemVerilog
module param_decoder #(
    parameter ADDR_WIDTH = 4,
    parameter OUT_WIDTH = 16
)(
    input [ADDR_WIDTH-1:0] address,
    input enable,
    output [OUT_WIDTH-1:0] select
);
    reg [OUT_WIDTH-1:0] decode;
    integer i;
    
    always @(*) begin
        decode = {OUT_WIDTH{1'b0}};
        // 初始化放在循环前
        i = 0;
        // for循环转换为while循环
        while (i < OUT_WIDTH) begin
            if (i == address) begin
                decode[i] = 1'b1;
            end
            // 迭代步骤放在循环体末尾
            i = i + 1;
        end
    end
    
    assign select = enable ? decode : {OUT_WIDTH{1'b0}};
endmodule