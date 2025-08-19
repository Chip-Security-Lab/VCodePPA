//SystemVerilog
//IEEE 1364-2005 Verilog标准
module pipelined_crossbar (
    input  wire        clock,
    input  wire        reset,
    input  wire [15:0] in0, in1, in2, in3,
    input  wire [1:0]  sel0, sel1, sel2, sel3,
    output wire [15:0] out0, out1, out2, out3
);
    // ======= STAGE 1: INPUT REGISTRATION =======
    // 为提高信号完整性，每个输入都单独注册
    reg [15:0] stage1_data [0:3];
    reg [1:0]  stage1_sel  [0:3];
    
    // ======= STAGE 2: INTERMEDIATE BUFFERING =======
    // 将输入信号分为两组，优化扇出负载
    reg [15:0] stage2_data_group0 [0:3]; // 为输出0和1服务
    reg [15:0] stage2_data_group1 [0:3]; // 为输出2和3服务
    reg [1:0]  stage2_sel  [0:3];
    
    // ======= STAGE 3: CROSSBAR SWITCHING =======
    // 执行实际的交叉开关操作
    reg [15:0] stage3_result [0:3];
    
    // ======= STAGE 4: OUTPUT REGISTRATION =======
    // 最终输出寄存器
    reg [15:0] stage4_output [0:3];
    
    // ======= STAGE 1: 输入注册 =======
    always @(posedge clock) begin
        if (reset) begin
            // 清零所有第一级寄存器
            stage1_data[0] <= 16'h0000;
            stage1_data[1] <= 16'h0000;
            stage1_data[2] <= 16'h0000;
            stage1_data[3] <= 16'h0000;
            
            stage1_sel[0] <= 2'b00;
            stage1_sel[1] <= 2'b00;
            stage1_sel[2] <= 2'b00;
            stage1_sel[3] <= 2'b00;
        end
        else begin
            // 注册所有输入数据和选择信号
            stage1_data[0] <= in0;
            stage1_data[1] <= in1;
            stage1_data[2] <= in2;
            stage1_data[3] <= in3;
            
            stage1_sel[0] <= sel0;
            stage1_sel[1] <= sel1;
            stage1_sel[2] <= sel2;
            stage1_sel[3] <= sel3;
        end
    end
    
    // ======= STAGE 2: 中间缓冲 =======
    always @(posedge clock) begin
        if (reset) begin
            // 清零所有第二级寄存器
            stage2_data_group0[0] <= 16'h0000;
            stage2_data_group0[1] <= 16'h0000;
            stage2_data_group0[2] <= 16'h0000;
            stage2_data_group0[3] <= 16'h0000;
            
            stage2_data_group1[0] <= 16'h0000;
            stage2_data_group1[1] <= 16'h0000;
            stage2_data_group1[2] <= 16'h0000;
            stage2_data_group1[3] <= 16'h0000;
            
            stage2_sel[0] <= 2'b00;
            stage2_sel[1] <= 2'b00;
            stage2_sel[2] <= 2'b00;
            stage2_sel[3] <= 2'b00;
        end
        else begin
            // 缓冲数据，将扇出分组以平衡负载
            stage2_data_group0[0] <= stage1_data[0];
            stage2_data_group0[1] <= stage1_data[1];
            stage2_data_group0[2] <= stage1_data[2];
            stage2_data_group0[3] <= stage1_data[3];
            
            stage2_data_group1[0] <= stage1_data[0];
            stage2_data_group1[1] <= stage1_data[1];
            stage2_data_group1[2] <= stage1_data[2];
            stage2_data_group1[3] <= stage1_data[3];
            
            // 缓冲选择信号
            stage2_sel[0] <= stage1_sel[0];
            stage2_sel[1] <= stage1_sel[1];
            stage2_sel[2] <= stage1_sel[2];
            stage2_sel[3] <= stage1_sel[3];
        end
    end
    
    // ======= STAGE 3: 交叉开关操作 =======
    always @(posedge clock) begin
        if (reset) begin
            // 清零所有第三级寄存器
            stage3_result[0] <= 16'h0000;
            stage3_result[1] <= 16'h0000;
            stage3_result[2] <= 16'h0000;
            stage3_result[3] <= 16'h0000;
        end
        else begin
            // 执行交叉开关操作，使用不同的缓冲组以平衡负载
            stage3_result[0] <= stage2_data_group0[stage2_sel[0]];
            stage3_result[1] <= stage2_data_group0[stage2_sel[1]];
            stage3_result[2] <= stage2_data_group1[stage2_sel[2]];
            stage3_result[3] <= stage2_data_group1[stage2_sel[3]];
        end
    end
    
    // ======= STAGE 4: 输出注册 =======
    always @(posedge clock) begin
        if (reset) begin
            // 清零所有输出寄存器
            stage4_output[0] <= 16'h0000;
            stage4_output[1] <= 16'h0000;
            stage4_output[2] <= 16'h0000;
            stage4_output[3] <= 16'h0000;
        end
        else begin
            // 输出结果注册
            stage4_output[0] <= stage3_result[0];
            stage4_output[1] <= stage3_result[1];
            stage4_output[2] <= stage3_result[2];
            stage4_output[3] <= stage3_result[3];
        end
    end
    
    // 输出分配
    assign out0 = stage4_output[0];
    assign out1 = stage4_output[1];
    assign out2 = stage4_output[2];
    assign out3 = stage4_output[3];
    
endmodule