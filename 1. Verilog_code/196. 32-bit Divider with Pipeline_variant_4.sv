//SystemVerilog
module divider_pipeline_32bit (
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    input wire [31:0] dividend,
    input wire [31:0] divisor,
    output wire [31:0] quotient,
    output wire [31:0] remainder,
    output wire valid_out
);

    // 常量定义 - 流水线级数
    localparam PIPELINE_STAGES = 16;
    
    // 流水线寄存器
    reg [31:0] dividend_stage [PIPELINE_STAGES-1:0];
    reg [31:0] divisor_stage [PIPELINE_STAGES-1:0];
    reg [31:0] quotient_stage [PIPELINE_STAGES-1:0];
    reg [31:0] remainder_stage [PIPELINE_STAGES-1:0];
    reg valid_stage [PIPELINE_STAGES:0];
    
    // 关键路径切割所需的临时寄存器
    reg [31:0] temp_remainder [PIPELINE_STAGES-1:0];
    reg [31:0] temp_quotient [PIPELINE_STAGES-1:0];
    reg [1:0] temp_bits [PIPELINE_STAGES-1:0];
    reg [31:0] compare_result [PIPELINE_STAGES-1:0];
    reg comparison_flag [PIPELINE_STAGES-1:0];
    
    // 初始流水线输入
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            valid_stage[0] <= 1'b0;
        end else begin
            valid_stage[0] <= valid_in;
        end
    end
    
    // 生成流水线阶段
    genvar i;
    generate
        for (i = 0; i < PIPELINE_STAGES; i = i + 1) begin: div_stage
            // 第一级流水线特殊处理 - 初始化计算
            if (i == 0) begin
                always @(posedge clk or negedge rst_n) begin
                    if (~rst_n) begin
                        dividend_stage[0] <= 32'h0;
                        divisor_stage[0] <= 32'h0;
                        quotient_stage[0] <= 32'h0;
                        remainder_stage[0] <= 32'h0;
                    end else if (valid_in) begin
                        dividend_stage[0] <= dividend;
                        divisor_stage[0] <= divisor;
                        // 初始化阶段 - 设置初始商和余数
                        quotient_stage[0] <= 32'h0;
                        remainder_stage[0] <= 32'h0;
                    end
                end
                
                // 第一阶段的组合逻辑准备
                always @(*) begin
                    temp_remainder[0] = {2'b00, dividend[31:2]};
                    compare_result[0] = {2'b00, dividend[31:2]} - divisor;
                    comparison_flag[0] = ({2'b00, dividend[31:2]} >= divisor);
                end
            end
            // 中间流水线阶段 - 执行分步计算，采用关键路径切割
            else begin
                // 阶段 1: 计算比较和临时结果
                always @(*) begin
                    if (i == 1) begin
                        // 初始化余数为被除数的高位
                        temp_remainder[i] = {2'b00, dividend_stage[i-1][31:2]};
                        temp_quotient[i] = {quotient_stage[i-1][29:0], 2'b00};
                        
                        // 计算比较结果
                        comparison_flag[i] = (temp_remainder[i] >= divisor_stage[i-1]);
                        compare_result[i] = temp_remainder[i] - divisor_stage[i-1];
                        temp_bits[i] = comparison_flag[i] ? 2'b01 : 2'b00;
                    end else begin
                        // 移位并计算下一个2位
                        temp_remainder[i] = {remainder_stage[i-1][29:0], dividend_stage[i-1][(32-i*2-1):(32-i*2-2)]};
                        temp_quotient[i] = quotient_stage[i-1];
                        
                        // 比较结果
                        comparison_flag[i] = (temp_remainder[i] >= divisor_stage[i-1]);
                        compare_result[i] = temp_remainder[i] - divisor_stage[i-1];
                        temp_bits[i] = comparison_flag[i] ? 2'b01 : 2'b00;
                    end
                end
                
                // 阶段 2: 寄存计算结果，切割关键路径
                always @(posedge clk or negedge rst_n) begin
                    if (~rst_n) begin
                        dividend_stage[i] <= 32'h0;
                        divisor_stage[i] <= 32'h0;
                        quotient_stage[i] <= 32'h0;
                        remainder_stage[i] <= 32'h0;
                        valid_stage[i] <= 1'b0;
                    end else begin
                        dividend_stage[i] <= dividend_stage[i-1];
                        divisor_stage[i] <= divisor_stage[i-1];
                        valid_stage[i] <= valid_stage[i-1];
                        
                        if (valid_stage[i-1]) begin
                            // 基于比较结果更新余数和商
                            if (i == 1) begin
                                remainder_stage[i] <= comparison_flag[i] ? compare_result[i] : temp_remainder[i];
                                quotient_stage[i] <= {temp_quotient[i][31:2], temp_bits[i]};
                            end else begin
                                remainder_stage[i] <= comparison_flag[i] ? compare_result[i] : temp_remainder[i];
                                
                                // 更新商的特定位
                                quotient_stage[i] <= temp_quotient[i];
                                quotient_stage[i][(i*2-1):(i*2-2)] <= temp_bits[i];
                            end
                        end else begin
                            quotient_stage[i] <= quotient_stage[i-1];
                            remainder_stage[i] <= remainder_stage[i-1];
                        end
                    end
                end
            end
        end
    endgenerate
    
    // 最终流水线输出阶段
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            valid_stage[PIPELINE_STAGES] <= 1'b0;
        end else begin
            valid_stage[PIPELINE_STAGES] <= valid_stage[PIPELINE_STAGES-1];
        end
    end
    
    // 输出赋值
    assign quotient = quotient_stage[PIPELINE_STAGES-1];
    assign remainder = remainder_stage[PIPELINE_STAGES-1];
    assign valid_out = valid_stage[PIPELINE_STAGES];

endmodule