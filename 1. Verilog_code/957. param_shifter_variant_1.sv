//SystemVerilog
module param_shifter #(
    parameter WIDTH = 12,
    parameter RESET_VALUE = 0,
    parameter PIPELINE_STAGES = 3  // 定义流水线级数
)(
    input wire i_Clk,
    input wire i_Rst,
    input wire i_DataIn,
    input wire i_Valid,            // 输入数据有效信号
    output wire o_Ready,           // 输入就绪信号
    output wire [WIDTH-1:0] o_DataOut,
    output wire o_Valid,           // 输出数据有效信号
    input wire i_Ready             // 输出就绪信号
);
    // 计算每级流水线处理的位宽
    localparam STAGE_WIDTH = (WIDTH + PIPELINE_STAGES - 1) / PIPELINE_STAGES;
    
    // 流水线寄存器
    reg [STAGE_WIDTH-1:0] r_Shift_stage1;
    reg [STAGE_WIDTH-1:0] r_Shift_stage2;
    reg [WIDTH-2*STAGE_WIDTH:0] r_Shift_stage3;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 流水线就绪信号传播
    wire ready_stage1, ready_stage2, ready_stage3;
    assign ready_stage3 = i_Ready;
    assign ready_stage2 = ready_stage3 || !valid_stage3;
    assign ready_stage1 = ready_stage2 || !valid_stage2;
    assign o_Ready = ready_stage1 || !valid_stage1;
    
    // 第一级流水线
    always @(posedge i_Clk) begin
        if (i_Rst) begin
            r_Shift_stage1 <= RESET_VALUE[WIDTH-1:WIDTH-STAGE_WIDTH];
            valid_stage1 <= 1'b0;
        end
        else if (o_Ready && i_Valid) begin
            r_Shift_stage1 <= {r_Shift_stage1[STAGE_WIDTH-2:0], i_DataIn};
            valid_stage1 <= 1'b1;
        end
        else if (ready_stage1) begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // 第二级流水线
    always @(posedge i_Clk) begin
        if (i_Rst) begin
            r_Shift_stage2 <= RESET_VALUE[WIDTH-STAGE_WIDTH-1:WIDTH-2*STAGE_WIDTH];
            valid_stage2 <= 1'b0;
        end
        else if (ready_stage2 && valid_stage1) begin
            r_Shift_stage2 <= {r_Shift_stage2[STAGE_WIDTH-2:0], r_Shift_stage1[STAGE_WIDTH-1]};
            valid_stage2 <= 1'b1;
        end
        else if (ready_stage2) begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // 第三级流水线
    always @(posedge i_Clk) begin
        if (i_Rst) begin
            r_Shift_stage3 <= RESET_VALUE[WIDTH-2*STAGE_WIDTH-1:0];
            valid_stage3 <= 1'b0;
        end
        else if (ready_stage3 && valid_stage2) begin
            r_Shift_stage3 <= {r_Shift_stage3[WIDTH-2*STAGE_WIDTH-2:0], r_Shift_stage2[STAGE_WIDTH-1]};
            valid_stage3 <= 1'b1;
        end
        else if (ready_stage3) begin
            valid_stage3 <= 1'b0;
        end
    end
    
    // 组合输出数据
    assign o_DataOut = {r_Shift_stage1, r_Shift_stage2, r_Shift_stage3};
    assign o_Valid = valid_stage3;
    
endmodule