//SystemVerilog
module int_ctrl_delay #(
    parameter DLY = 2
)(
    input wire clk,
    input wire rst_n,  // 添加复位信号
    input wire int_in,
    input wire valid_in,  // 添加输入有效信号
    output wire int_out,
    output wire valid_out  // 添加输出有效信号
);
    // 定义流水线寄存器
    reg [DLY-1:0] int_pipeline;
    reg [DLY-1:0] valid_pipeline;
    
    // 流水线控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_pipeline <= {DLY{1'b0}};
            valid_pipeline <= {DLY{1'b0}};
        end else begin
            // 数据流水线移位
            int_pipeline <= {int_pipeline[DLY-2:0], int_in};
            // 有效信号流水线移位
            valid_pipeline <= {valid_pipeline[DLY-2:0], valid_in};
        end
    end
    
    // 输出赋值
    assign int_out = int_pipeline[DLY-1];
    assign valid_out = valid_pipeline[DLY-1];
    
endmodule