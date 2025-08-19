//SystemVerilog
module param_shifter #(
    parameter WIDTH = 12,
    parameter RESET_VALUE = 0,
    parameter PIPELINE_STAGES = 4  // 流水线级数
)(
    input wire i_Clk,
    input wire i_Rst,
    input wire i_DataIn,
    input wire i_Valid,  // 输入数据有效信号
    output wire o_Ready, // 准备接收新数据信号
    output wire [WIDTH-1:0] o_DataOut,
    output wire o_Valid   // 输出数据有效信号
);
    // 使用局部参数提高可读性和重用性
    localparam MSB = WIDTH-1;
    localparam STAGE_WIDTH = (WIDTH + PIPELINE_STAGES - 1) / PIPELINE_STAGES; // 每级流水线处理的位数
    
    // 流水线各级的移位寄存器
    (* keep = "true" *) reg [MSB:0] r_Stage_Data[PIPELINE_STAGES:0];
    
    // 流水线控制信号
    reg [PIPELINE_STAGES:0] r_Stage_Valid;
    
    // 准备接收新数据信号
    assign o_Ready = 1'b1; // 简单实现，始终准备接收
    
    // 输出信号关联
    assign o_DataOut = r_Stage_Data[PIPELINE_STAGES];
    assign o_Valid = r_Stage_Valid[PIPELINE_STAGES];
    
    integer i;
    
    always @(posedge i_Clk or posedge i_Rst) begin
        if (i_Rst) begin
            // 复位所有流水线寄存器
            for (i = 0; i <= PIPELINE_STAGES; i = i + 1) begin
                r_Stage_Data[i] <= RESET_VALUE;
                r_Stage_Valid[i] <= 1'b0;
            end
        end
        else begin
            // 第一级流水线接收输入数据
            if (i_Valid && o_Ready) begin
                r_Stage_Data[0] <= {r_Stage_Data[0][MSB-1:0], i_DataIn};
                r_Stage_Valid[0] <= 1'b1;
            end
            
            // 数据在流水线级之间流动
            for (i = 1; i <= PIPELINE_STAGES; i = i + 1) begin
                r_Stage_Data[i] <= r_Stage_Data[i-1];
                r_Stage_Valid[i] <= r_Stage_Valid[i-1];
            end
        end
    end
    
    // 流水线级间数据处理逻辑
    // 在实际应用中，可以在各级之间添加不同的组合逻辑处理
    
endmodule