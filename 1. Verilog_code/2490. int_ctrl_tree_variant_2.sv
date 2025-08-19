//SystemVerilog
module int_ctrl_tree #(
    parameter LEVEL = 3
)(
    input wire clk,          // 添加时钟信号
    input wire rst_n,        // 添加复位信号
    input wire [2**LEVEL-1:0] req_vec,
    output reg [LEVEL-1:0] grant_code
);
    // 内部信号声明
    reg [2**LEVEL-1:0] req_vec_reg;
    wire [LEVEL-1:0] combinational_grant;
    reg [LEVEL-1:0] pipeline_grant;  // 增加流水线寄存器
    
    // 输入寄存器级 - 减少输入负载，改善时序
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            req_vec_reg <= {(2**LEVEL){1'b0}};
        else
            req_vec_reg <= req_vec;
    end
    
    // 递归树结构的核心逻辑
    generate
        if (LEVEL == 1) begin: BASE_CASE
            // 基本情况 - 单级仲裁
            assign combinational_grant = req_vec_reg[1] ? 1'b1 : 1'b0;
        end
        else begin: RECURSIVE_CASE
            // 主数据路径的信号声明
            wire [2**(LEVEL-1)-1:0] upper_half; // 上半部分请求
            wire [2**(LEVEL-1)-1:0] lower_half; // 下半部分请求
            wire upper_has_request;             // 上半部分有效标志
            
            // 流水线寄存器 - 分段数据路径
            reg upper_has_request_reg;
            reg [LEVEL-2:0] upper_subtree_code_reg; // 添加子树流水线寄存器
            reg [LEVEL-2:0] lower_subtree_code_reg; // 添加子树流水线寄存器
            
            // 子树编码输出
            wire [LEVEL-2:0] upper_subtree_code;
            wire [LEVEL-2:0] lower_subtree_code;
            
            // 路径分割 - 清晰定义数据流
            assign upper_half = req_vec_reg[2**(LEVEL)-1:2**(LEVEL-1)];
            assign lower_half = req_vec_reg[2**(LEVEL-1)-1:0];
            
            // 优化上半部分有效检测 - 使用OR归约操作符
            assign upper_has_request = |upper_half;
            
            // 上半部分子树实例
            int_ctrl_tree #(.LEVEL(LEVEL-1)) upper_tree (
                .clk(clk),
                .rst_n(rst_n),
                .req_vec(upper_half),
                .grant_code(upper_subtree_code)
            );
            
            // 下半部分子树实例
            int_ctrl_tree #(.LEVEL(LEVEL-1)) lower_tree (
                .clk(clk),
                .rst_n(rst_n),
                .req_vec(lower_half),
                .grant_code(lower_subtree_code)
            );
            
            // 流水线寄存器 - 存储中间计算结果
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    upper_has_request_reg <= 1'b0;
                    upper_subtree_code_reg <= {(LEVEL-1){1'b0}};
                    lower_subtree_code_reg <= {(LEVEL-1){1'b0}};
                end
                else begin
                    upper_has_request_reg <= upper_has_request;
                    upper_subtree_code_reg <= upper_subtree_code;
                    lower_subtree_code_reg <= lower_subtree_code;
                end
            end
            
            // 最终编码组合逻辑
            assign combinational_grant = {
                upper_has_request_reg,
                upper_has_request_reg ? upper_subtree_code_reg : lower_subtree_code_reg
            };
        end
    endgenerate
    
    // 输出流水线寄存器 - 改善扇出和时序
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pipeline_grant <= {LEVEL{1'b0}};
        else
            pipeline_grant <= combinational_grant;
    end
    
    // 最终输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            grant_code <= {LEVEL{1'b0}};
        else
            grant_code <= pipeline_grant;
    end
endmodule