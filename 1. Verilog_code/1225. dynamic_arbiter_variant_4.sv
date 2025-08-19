//SystemVerilog
module dynamic_arbiter #(parameter WIDTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    input [WIDTH-1:0] pri_map,  // External priority
    output reg [WIDTH-1:0] grant_o
);

    wire [WIDTH-1:0] masked_req;
    reg [WIDTH-1:0] next_grant;
    wire has_request;
    wire [WIDTH-1:0] priority_select [WIDTH:0];
    
    // 屏蔽请求与优先级映射
    assign masked_req = req_i & pri_map;
    assign has_request = |masked_req;
    
    // 显式多路复用器结构实现优先级编码
    // 默认值设置 - 无请求情况
    assign priority_select[0] = {WIDTH{1'b0}};
    
    // 生成各优先级情况下的输出
    genvar i;
    generate
        for(i = 0; i < WIDTH; i = i + 1) begin : PRIORITY_MUX
            // 创建每一位的选择mask
            wire [WIDTH-1:0] mask;
            assign mask = {{(WIDTH-i-1){1'b0}}, 1'b1, {i{1'b0}}};
            
            // 当前位置被选择的条件
            wire select_this_bit;
            assign select_this_bit = |(masked_req & mask);
            
            // 多路复用器结构 - 选择当前位或保持前一优先级结果
            assign priority_select[i+1] = select_this_bit ? mask : priority_select[i];
        end
    endgenerate
    
    // 最终优先级选择逻辑
    always @(*) begin
        // 选择有请求时的优先级结果，否则为全0
        next_grant = has_request ? priority_select[WIDTH] : {WIDTH{1'b0}};
    end

    // 同步寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant_o <= {WIDTH{1'b0}};
        end else begin
            grant_o <= next_grant;
        end
    end

endmodule