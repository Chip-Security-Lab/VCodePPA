//SystemVerilog
module parallel_arbiter #(parameter WIDTH=8) (
    input [WIDTH-1:0] req_i,
    output [WIDTH-1:0] grant_o
);
    // 使用查找表辅助减法器实现
    wire [WIDTH-1:0] req_minus_1;
    wire [WIDTH-1:0] lower_priority_reqs;
    
    // 减法器查找表实现
    reg [WIDTH-1:0] sub_lut [0:WIDTH-1];
    
    // 初始化查找表
    integer j;
    initial begin
        for (j = 0; j < WIDTH; j = j + 1) begin
            sub_lut[j] = (1'b1 << j) - 1'b1;
        end
    end
    
    // 使用查找表获取(1<<i)-1的值
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_priority
            // 从查找表中获取减法结果
            wire [WIDTH-1:0] subtraction_result = sub_lut[i];
            // 与请求信号相与获取低优先级请求
            assign lower_priority_reqs[i] = |(req_i & subtraction_result);
        end
    endgenerate
    
    // 计算优先级掩码：保留所有没有更低优先级请求的位
    wire [WIDTH-1:0] pri_mask = req_i & ~(req_i & lower_priority_reqs);
    
    // 输出优先级掩码，它包含了最高优先级的单一请求位
    assign grant_o = pri_mask;
endmodule