//SystemVerilog
module multiphase_clock(
    input sys_clk,
    input rst,
    input valid,         // 替代原来的req信号
    output reg ready,    // 替代原来的ack信号
    output [7:0] phase_clks
);
    reg [7:0] shift_reg;
    reg data_accepted;
    
    always @(posedge sys_clk or posedge rst) begin
        if (rst) begin
            shift_reg <= 8'b00000001;
            ready <= 1'b1;        // 初始状态就准备好接收数据
            data_accepted <= 1'b0;
        end else begin
            // 正常轮转时钟相位
            shift_reg <= {shift_reg[6:0], shift_reg[7]};
            
            // Valid-Ready握手逻辑
            if (valid && ready) begin
                // 握手成功，数据被接收
                data_accepted <= 1'b1;
                ready <= 1'b0;    // 接收后暂时不能接收新数据
            end else if (data_accepted) begin
                // 完成处理周期，可以接收新数据
                data_accepted <= 1'b0;
                ready <= 1'b1;
            end
        end
    end
    
    assign phase_clks = shift_reg;
endmodule