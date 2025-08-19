//SystemVerilog
module multistage_shifter(
    input clk,               // 时钟信号
    input rst_n,             // 复位信号，低电平有效
    
    // 输入接口 - Valid-Ready协议
    input [7:0] data_in,     // 输入数据
    input [2:0] shift_amt,   // 移位量
    input valid_in,          // 输入有效信号
    output reg ready_in,     // 输入就绪信号
    
    // 输出接口 - Valid-Ready协议
    output reg [7:0] data_out, // 输出数据
    output reg valid_out,      // 输出有效信号
    input ready_out           // 输出就绪信号
);

    // 内部寄存器和连线
    reg [7:0] data_reg;
    reg [2:0] shift_amt_reg;
    reg processing;
    
    wire [7:0] stage0_out, stage1_out, result;
    
    // 多级移位逻辑
    assign stage0_out = shift_amt_reg[0] ? {data_reg[6:0], 1'b0} : data_reg;
    assign stage1_out = shift_amt_reg[1] ? {stage0_out[5:0], 2'b00} : stage0_out;
    assign result = shift_amt_reg[2] ? {stage1_out[3:0], 4'b0000} : stage1_out;
    
    // Valid-Ready握手状态机
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            ready_in <= 1'b1;
            valid_out <= 1'b0;
            processing <= 1'b0;
            data_out <= 8'b0;
            data_reg <= 8'b0;
            shift_amt_reg <= 3'b0;
        end else begin
            // 处理输入数据
            if (valid_in && ready_in) begin
                data_reg <= data_in;
                shift_amt_reg <= shift_amt;
                processing <= 1'b1;
                ready_in <= 1'b0;
            end
            
            // 处理输出数据
            if (processing) begin
                data_out <= result;
                valid_out <= 1'b1;
                processing <= 1'b0;
            end
            
            // 当输出握手完成
            if (valid_out && ready_out) begin
                valid_out <= 1'b0;
                ready_in <= 1'b1;
            end
        end
    end
    
endmodule