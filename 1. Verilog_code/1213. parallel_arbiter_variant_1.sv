//SystemVerilog
module parallel_arbiter #(
    parameter WIDTH = 8
) (
    input  wire             clk,      // 时钟信号
    input  wire             rst_n,    // 复位信号，低电平有效
    input  wire [WIDTH-1:0] req_i,    // 请求输入信号
    output reg  [WIDTH-1:0] grant_o   // 授权输出信号
);

    // 内部信号声明 - 分割数据流路径
    reg  [WIDTH-1:0]   req_stage1;          // 第一级流水线寄存器
    reg  [WIDTH-1:0]   req_stage2;          // 第二级流水线寄存器
    
    wire [WIDTH*2-1:0] ext_req_stage2;      // 扩展的请求信号
    reg  [WIDTH*2-1:0] ext_req_stage3;      // 第三级流水线寄存器
    
    wire [WIDTH*2-1:0] shifted_mask_stage3; // 移位掩码
    reg  [WIDTH*2-1:0] shifted_mask_stage4; // 第四级流水线寄存器
    
    wire [WIDTH-1:0]   priority_mask_stage4;// 优先级掩码
    reg  [WIDTH-1:0]   priority_mask_stage5;// 第五级流水线寄存器
    
    wire [WIDTH-1:0]   grant_next_stage5;   // 下一个授权值
    reg  [WIDTH-1:0]   grant_next_stage6;   // 第六级流水线寄存器

    // 第一级流水线 - 输入寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_stage1 <= {WIDTH{1'b0}};
        end else begin
            req_stage1 <= req_i;
        end
    end

    // 第二级流水线 - 再次寄存请求以进一步减少关键路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_stage2 <= {WIDTH{1'b0}};
        end else begin
            req_stage2 <= req_stage1;
        end
    end

    // 扩展请求信号处理 - 组合逻辑
    assign ext_req_stage2 = {req_stage2, {WIDTH{1'b0}}};
    
    // 第三级流水线 - 寄存扩展请求信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ext_req_stage3 <= {2*WIDTH{1'b0}};
        end else begin
            ext_req_stage3 <= ext_req_stage2;
        end
    end
    
    // 移位掩码计算 - 组合逻辑
    assign shifted_mask_stage3 = ext_req_stage3 >> 1;
    
    // 第四级流水线 - 寄存移位掩码
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shifted_mask_stage4 <= {2*WIDTH{1'b0}};
        end else begin
            shifted_mask_stage4 <= shifted_mask_stage3;
        end
    end
    
    // 优先级掩码计算 - 组合逻辑
    assign priority_mask_stage4 = req_stage2 & ~shifted_mask_stage4[WIDTH*2-1:WIDTH];
    
    // 第五级流水线 - 寄存优先级掩码
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_mask_stage5 <= {WIDTH{1'b0}};
        end else begin
            priority_mask_stage5 <= priority_mask_stage4;
        end
    end
    
    // 最终授权计算 - 组合逻辑
    assign grant_next_stage5 = priority_mask_stage5 & (~priority_mask_stage5 + 1);
    
    // 第六级流水线 - 寄存授权信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant_next_stage6 <= {WIDTH{1'b0}};
        end else begin
            grant_next_stage6 <= grant_next_stage5;
        end
    end

    // 输出寄存器 - 第七级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant_o <= {WIDTH{1'b0}};
        end else begin
            grant_o <= grant_next_stage6;
        end
    end

endmodule