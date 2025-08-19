//SystemVerilog
module int_ctrl_pipeline #(
    parameter DW = 8
)(
    input  logic         clk,
    input  logic         en,
    input  logic [DW-1:0] req_in,
    output logic [DW-1:0] req_q,
    output logic [3:0]   curr_pri
);
    // ===== 流水线级：阶段1 - 输入捕获 =====
    logic [DW-1:0] req_stage1_reg;  // 第一级流水线寄存器
    
    // ===== 流水线级：阶段2 - 优先级编码 =====
    logic [DW-1:0] combined_req_stage2; // 第二级流水线中的组合请求
    logic [3:0]    pri_stage2;          // 第二级流水线中的优先级结果
    logic [DW-1:0] mask_stage2;         // 用于清除已处理请求的掩码
    logic [DW-1:0] next_req_stage2;     // 下一个请求状态
    
    // ===== 功能定义：优先级编码器 =====
    function automatic logic [3:0] find_highest_pri;
        input logic [DW-1:0] req;
        logic [3:0] result;
    begin
        case(1'b1) // 使用优化的独热码检测方式
            req[7]: result = 4'd7;
            req[6]: result = 4'd6;
            req[5]: result = 4'd5;
            req[4]: result = 4'd4;
            req[3]: result = 4'd3;
            req[2]: result = 4'd2;
            req[1]: result = 4'd1;
            req[0]: result = 4'd0;
            default: result = 4'd0;
        endcase
        return result;
    end
    endfunction
    
    // ===== 阶段1：输入捕获流水线 =====
    always_ff @(posedge clk) begin
        req_stage1_reg <= req_in; // 捕获输入请求
    end
    
    // ===== 阶段2：组合逻辑路径 =====
    // 数据流路径分解为更清晰的步骤
    always_comb begin
        // 1. 组合当前请求与先前未处理的请求
        combined_req_stage2 = req_stage1_reg | req_q;
        
        // 2. 确定最高优先级
        pri_stage2 = find_highest_pri(combined_req_stage2);
        
        // 3. 创建掩码以清除已处理的最高优先级请求
        mask_stage2 = {{(DW-1){1'b0}}, 1'b1} << pri_stage2;
        
        // 4. 计算下一个请求状态（清除已处理的位）
        next_req_stage2 = combined_req_stage2 & ~mask_stage2;
    end
    
    // ===== 阶段2：状态更新 =====
    always_ff @(posedge clk) begin
        if (en) begin
            // 更新输出寄存器
            req_q <= next_req_stage2;
            curr_pri <= pri_stage2;
        end
    end
    
endmodule