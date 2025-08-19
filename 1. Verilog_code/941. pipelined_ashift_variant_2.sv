//SystemVerilog
module pipelined_ashift (
    input clk, rst,
    input [31:0] din,
    input [4:0] shift,
    input valid_in,     // 输入数据有效信号
    output ready_out,   // 输出接收就绪信号
    output [31:0] dout,
    output valid_out,   // 输出数据有效信号
    input ready_in      // 输入接收就绪信号
);
    // 内部握手信号和数据寄存器
    reg [31:0] stage1, stage2, dout_reg;
    reg valid_stage1, valid_stage2, valid_out_reg;
    wire stall;
    
    // 握手控制逻辑
    assign stall = valid_out_reg && !ready_in;
    assign ready_out = !stall;
    assign valid_out = valid_out_reg;
    assign dout = dout_reg;
    
    always @(posedge clk) begin
        if (rst) begin
            // 复位所有寄存器
            stage1 <= 32'b0;
            stage2 <= 32'b0;
            dout_reg <= 32'b0;
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
            valid_out_reg <= 1'b0;
        end else if (!stall) begin
            // 当没有停滞时，正常数据流动
            stage1 <= din >>> (shift[4:3] * 8);    // 处理高2位
            stage2 <= stage1 >>> (shift[2:1] * 2); // 处理中间2位
            dout_reg <= stage2 >>> shift[0];       // 处理最后1位
            
            // 握手信号流动
            valid_stage1 <= valid_in;
            valid_stage2 <= valid_stage1;
            valid_out_reg <= valid_stage2;
        end
    end
endmodule