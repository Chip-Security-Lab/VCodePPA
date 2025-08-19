//SystemVerilog
module param_ring_counter #(
    parameter CNT_WIDTH = 8
)(
    input wire clk_in,
    input wire rst_in,
    input wire enable_in,
    output wire [CNT_WIDTH-1:0] counter_out,
    output wire valid_out
);
    // 定义流水线寄存器
    reg [CNT_WIDTH-1:0] counter_stage1_reg;
    reg [CNT_WIDTH-1:0] counter_stage2_reg;
    reg [CNT_WIDTH-1:0] counter_stage3_reg;
    
    // 流水线控制信号
    reg valid_stage1_reg;
    reg valid_stage2_reg;
    reg valid_stage3_reg;
    
    // 预计算初始值常量，减少运行时逻辑
    localparam [CNT_WIDTH-1:0] INIT_VALUE = {{(CNT_WIDTH-1){1'b0}}, 1'b1};
    
    // 将环形计数逻辑分离为低位和高位操作，均衡路径延迟
    wire low_bit_shift = counter_stage3_reg[CNT_WIDTH-1];
    wire [CNT_WIDTH-2:0] shifted_bits = counter_stage3_reg[CNT_WIDTH-2:0];
    
    // 第一级流水线逻辑 - 优化后的环形移位计算
    wire [CNT_WIDTH-1:0] next_counter_stage1;
    assign next_counter_stage1 = rst_in ? INIT_VALUE : {shifted_bits, low_bit_shift};
    
    // 使用非阻塞赋值确保同步更新所有流水线级
    always @(posedge clk_in) begin
        if (rst_in) begin
            counter_stage1_reg <= INIT_VALUE;
            valid_stage1_reg <= 1'b0;
        end else if (enable_in) begin
            counter_stage1_reg <= next_counter_stage1;
            valid_stage1_reg <= 1'b1;
        end
    end
    
    // 第二级流水线寄存器
    always @(posedge clk_in) begin
        if (rst_in) begin
            counter_stage2_reg <= {CNT_WIDTH{1'b0}};
            valid_stage2_reg <= 1'b0;
        end else if (enable_in) begin
            counter_stage2_reg <= counter_stage1_reg;
            valid_stage2_reg <= valid_stage1_reg;
        end
    end
    
    // 第三级流水线寄存器
    always @(posedge clk_in) begin
        if (rst_in) begin
            counter_stage3_reg <= {CNT_WIDTH{1'b0}};
            valid_stage3_reg <= 1'b0;
        end else if (enable_in) begin
            counter_stage3_reg <= counter_stage2_reg;
            valid_stage3_reg <= valid_stage2_reg;
        end
    end
    
    // 输出赋值 - 直接连接避免额外逻辑
    assign counter_out = counter_stage3_reg;
    assign valid_out = valid_stage3_reg;
    
endmodule