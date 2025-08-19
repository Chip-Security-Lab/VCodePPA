//SystemVerilog - IEEE 1364-2005
module MultiPhaseShiftReg #(parameter PHASES=4, WIDTH=8) (
    input [PHASES-1:0] phase_clk,
    input serial_in,
    input rst_n,                    // 添加复位信号
    input pipeline_en,              // 添加流水线使能信号
    output [PHASES-1:0] phase_out,
    output [PHASES-1:0] valid_out   // 添加有效输出信号
);

    // 流水线级数定义 - 将移位寄存器分为多个流水线级
    localparam PIPE_STAGES = 3;     // 设定为3级流水线
    
    // 各阶段流水线有效信号
    reg [PIPE_STAGES-1:0] valid_pipeline [0:PHASES-1];
    
    // 第一级流水线寄存器 - 输入阶段
    reg serial_in_stage1;
    reg [PHASES-1:0] serial_in_phase_stage1;
    
    // 第二级流水线寄存器 - 中间处理阶段
    reg [PHASES-1:0][WIDTH/2-1:0] shift_reg_stage2;
    
    // 第三级流水线寄存器 - 输出阶段
    reg [PHASES-1:0][WIDTH/2-1:0] shift_reg_stage3;

    // 第一级流水线 - 输入寄存
    always @(posedge phase_clk[0] or negedge rst_n) begin
        if (!rst_n) begin
            serial_in_stage1 <= 1'b0;
            valid_pipeline[0][0] <= 1'b0;
        end else if (pipeline_en) begin
            serial_in_stage1 <= serial_in;
            valid_pipeline[0][0] <= 1'b1;
        end
    end
    
    genvar i;
    generate
        for(i=0; i<PHASES; i=i+1) begin : phase_pipeline_regs
            
            // 第一级流水线 - 每相位输入寄存
            always @(posedge phase_clk[i] or negedge rst_n) begin
                if (!rst_n) begin
                    serial_in_phase_stage1[i] <= 1'b0;
                    valid_pipeline[i][0] <= 1'b0;
                end else if (pipeline_en) begin
                    serial_in_phase_stage1[i] <= serial_in_stage1;
                    valid_pipeline[i][0] <= valid_pipeline[0][0];
                end
            end
            
            // 第二级流水线 - 前半部分移位处理
            always @(posedge phase_clk[i] or negedge rst_n) begin
                if (!rst_n) begin
                    shift_reg_stage2[i] <= {(WIDTH/2){1'b0}};
                    valid_pipeline[i][1] <= 1'b0;
                end else if (pipeline_en) begin
                    if (WIDTH > 2) begin
                        // 前半部分移位运算
                        shift_reg_stage2[i] <= {shift_reg_stage2[i][WIDTH/2-2:0], serial_in_phase_stage1[i]};
                    end else begin
                        shift_reg_stage2[i][0] <= serial_in_phase_stage1[i];
                    end
                    valid_pipeline[i][1] <= valid_pipeline[i][0];
                end
            end
            
            // 第三级流水线 - 后半部分移位处理
            always @(posedge phase_clk[i] or negedge rst_n) begin
                if (!rst_n) begin
                    shift_reg_stage3[i] <= {(WIDTH/2){1'b0}};
                    valid_pipeline[i][2] <= 1'b0;
                end else if (pipeline_en) begin
                    if (WIDTH > 2) begin
                        // 后半部分移位运算，输入来自第二级的最高位
                        shift_reg_stage3[i] <= {shift_reg_stage3[i][WIDTH/2-2:0], shift_reg_stage2[i][WIDTH/2-1]};
                    end else begin
                        shift_reg_stage3[i][0] <= shift_reg_stage2[i][0]; 
                    end
                    valid_pipeline[i][2] <= valid_pipeline[i][1];
                end
            end
            
            // 输出是第三级流水线的最高位
            assign phase_out[i] = shift_reg_stage3[i][WIDTH/2-1];
            assign valid_out[i] = valid_pipeline[i][2];
        end
    endgenerate
endmodule