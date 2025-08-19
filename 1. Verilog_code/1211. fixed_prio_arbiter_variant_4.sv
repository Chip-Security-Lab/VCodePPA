//SystemVerilog
module fixed_prio_arbiter #(parameter WIDTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
    // 内部信号
    reg [WIDTH-1:0] grant_next;
    
    // 查找表辅助实现
    reg [WIDTH-1:0] lut_based_result;
    reg [2:0] req_index;
    
    // 查找索引计算
    always @(*) begin
        // 默认值
        req_index = 3'b000;
        
        // 计算最高优先级请求的索引
        if (req_i[0]) req_index = 3'b001;
        else if (req_i[1]) req_index = 3'b010;
        else if (req_i[2]) req_index = 3'b011;
        else if (req_i[3]) req_index = 3'b100;
    end
    
    // 基于查找表的仲裁逻辑
    always @(*) begin
        case(req_index)
            3'b000: lut_based_result = 4'b0000; // 无请求
            3'b001: lut_based_result = 4'b0001; // 请求0有效
            3'b010: lut_based_result = 4'b0010; // 请求1有效
            3'b011: lut_based_result = 4'b0100; // 请求2有效
            3'b100: lut_based_result = 4'b1000; // 请求3有效
            default: lut_based_result = 4'b0000;
        endcase
        
        // 最终结果
        grant_next = lut_based_result;
    end

    // 寄存器阶段
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            grant_o <= {WIDTH{1'b0}};
        else
            grant_o <= grant_next;
    end
endmodule