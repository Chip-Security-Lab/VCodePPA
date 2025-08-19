//SystemVerilog
module int_ctrl_trig_type #(
    parameter WIDTH = 4
)(
    input wire clk,
    input wire rst_n,                // 添加复位信号
    input wire [WIDTH-1:0] int_src,
    input wire [WIDTH-1:0] trig_type,  // 0=level 1=edge
    input wire valid_in,             // 输入有效信号
    output wire valid_out,           // 输出有效信号
    output wire [WIDTH-1:0] int_out
);

    // 流水线寄存器 - 第一级
    reg [WIDTH-1:0] int_src_stage1;
    reg [WIDTH-1:0] trig_type_stage1;
    reg valid_stage1;
    reg [WIDTH-1:0] sync_reg, prev_reg;

    // 流水线寄存器 - 第二级
    reg [WIDTH-1:0] int_src_stage2;
    reg [WIDTH-1:0] trig_type_stage2;
    reg valid_stage2;
    reg [WIDTH-1:0] edge_detect_result;
    reg [WIDTH-1:0] level_detect_result;

    // 流水线寄存器 - 第三级
    reg [WIDTH-1:0] int_out_reg;
    reg valid_stage3;

    // 第一级流水线 - 输入同步
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_src_stage1 <= {WIDTH{1'b0}};
            trig_type_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            int_src_stage1 <= int_src;
            trig_type_stage1 <= trig_type;
            valid_stage1 <= valid_in;
        end
    end

    // 第一级流水线 - 边沿检测准备
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_reg <= {WIDTH{1'b0}};
            prev_reg <= {WIDTH{1'b0}};
        end else begin
            prev_reg <= sync_reg;
            sync_reg <= int_src;
        end
    end

    // 第二级流水线 - 数据传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_src_stage2 <= {WIDTH{1'b0}};
            trig_type_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            int_src_stage2 <= int_src_stage1;
            trig_type_stage2 <= trig_type_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // 第二级流水线 - 边沿检测计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            edge_detect_result <= {WIDTH{1'b0}};
        end else begin
            edge_detect_result <= sync_reg & ~prev_reg;  // 边沿检测
        end
    end

    // 第二级流水线 - 电平检测计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            level_detect_result <= {WIDTH{1'b0}};
        end else begin
            level_detect_result <= sync_reg;  // 电平检测
        end
    end

    // 第三级流水线 - 有效信号传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage3 <= 1'b0;
        end else begin
            valid_stage3 <= valid_stage2;
        end
    end

    // 第三级流水线 - 触发类型选择
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_out_reg <= {WIDTH{1'b0}};
        end else begin
            // 按位选择逻辑
            for (integer i = 0; i < WIDTH; i = i + 1) begin
                int_out_reg[i] <= trig_type_stage2[i] ? edge_detect_result[i] : level_detect_result[i];
            end
        end
    end

    // 输出赋值
    assign int_out = int_out_reg;
    assign valid_out = valid_stage3;

endmodule