//SystemVerilog
module param_shifter #(
    parameter WIDTH = 12,
    parameter RESET_VALUE = 0,
    parameter PIPELINE_STAGES = 2  // 新增流水线级数参数
)(
    input wire i_Clk,
    input wire i_Rst,
    input wire i_DataIn,
    output wire [WIDTH-1:0] o_DataOut
);
    // 分段流水线实现的移位寄存器
    // 将移位寄存器分成多个段以改善时序
    localparam STAGE_WIDTH = (WIDTH + PIPELINE_STAGES - 1) / PIPELINE_STAGES;
    
    // 第一级移位寄存器
    reg [STAGE_WIDTH-1:0] r_Shift_Stage1;
    // 中间级移位寄存器 (如果PIPELINE_STAGES > 2)
    reg [(WIDTH-2*STAGE_WIDTH)-1:0] r_Shift_Mid;
    // 最后一级移位寄存器
    reg [STAGE_WIDTH-1:0] r_Shift_Final;
    
    // 级间同步信号
    reg stage1_to_mid;
    reg mid_to_final;
    
    // 第一级移位操作
    always @(posedge i_Clk) begin
        if (i_Rst) begin
            r_Shift_Stage1 <= RESET_VALUE[STAGE_WIDTH-1:0];
            stage1_to_mid <= 1'b0;
        end else begin
            // 最高位将传递到下一级
            stage1_to_mid <= r_Shift_Stage1[STAGE_WIDTH-1];
            // 第一级移位
            r_Shift_Stage1 <= {r_Shift_Stage1[STAGE_WIDTH-2:0], i_DataIn};
        end
    end
    
    // 中间级移位操作 (根据WIDTH和PIPELINE_STAGES参数动态调整)
    generate
        if (PIPELINE_STAGES > 2 && WIDTH > 2*STAGE_WIDTH) begin
            always @(posedge i_Clk) begin
                if (i_Rst) begin
                    r_Shift_Mid <= RESET_VALUE[WIDTH-STAGE_WIDTH-1:STAGE_WIDTH];
                    mid_to_final <= 1'b0;
                end else begin
                    // 最高位将传递到下一级
                    mid_to_final <= r_Shift_Mid[WIDTH-2*STAGE_WIDTH-1];
                    // 中间级移位
                    r_Shift_Mid <= {r_Shift_Mid[WIDTH-2*STAGE_WIDTH-2:0], stage1_to_mid};
                end
            end
        end else begin
            always @(posedge i_Clk) begin
                mid_to_final <= stage1_to_mid;
            end
        end
    endgenerate
    
    // 最终级移位操作
    always @(posedge i_Clk) begin
        if (i_Rst)
            r_Shift_Final <= RESET_VALUE[WIDTH-1:WIDTH-STAGE_WIDTH];
        else
            r_Shift_Final <= {r_Shift_Final[STAGE_WIDTH-2:0], 
                             (PIPELINE_STAGES > 2) ? mid_to_final : stage1_to_mid};
    end
    
    // 组合输出逻辑
    generate
        if (PIPELINE_STAGES == 2) begin
            assign o_DataOut = {r_Shift_Final, r_Shift_Stage1};
        end else begin
            assign o_DataOut = {r_Shift_Final, r_Shift_Mid, r_Shift_Stage1};
        end
    endgenerate
    
endmodule