//SystemVerilog
module LUT_Hamming_Encoder(
    input wire clk,              // 时钟信号
    input wire rst_n,            // 复位信号
    input wire [3:0] data_in,    // 输入数据
    input wire data_req,         // 数据请求信号(之前的data_valid)
    output reg [6:0] code_out,   // 输出汉明码
    output reg code_req,         // 输出请求信号(之前的code_valid)
    input wire code_ack          // 从接收方返回的应答信号(新增)
);
    // 内部状态和控制信号
    reg [3:0] data_stage1;
    reg data_req_stage1;
    reg waiting_ack;
    
    // LUT存储预计算的汉明码
    reg [6:0] ham_rom [0:15];
    
    // 初始化LUT
    initial begin
        $readmemh("hamming_lut.hex", ham_rom);
    end
    
    // 第一级流水线 - 输入数据寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 4'b0;
            data_req_stage1 <= 1'b0;
        end else begin
            if (!waiting_ack || code_ack) begin
                data_stage1 <= data_in;
                data_req_stage1 <= data_req;
            end
        end
    end
    
    // 第二级流水线 - 查表并输出，实现请求-应答握手逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            code_out <= 7'b0;
            code_req <= 1'b0;
            waiting_ack <= 1'b0;
        end else begin
            if (data_req_stage1 && !waiting_ack) begin
                // 新数据到达且未在等待应答
                code_out <= ham_rom[data_stage1];
                code_req <= 1'b1;
                waiting_ack <= 1'b1;
            end else if (waiting_ack && code_ack) begin
                // 收到应答，完成传输
                code_req <= 1'b0;
                waiting_ack <= 1'b0;
            end
        end
    end
endmodule