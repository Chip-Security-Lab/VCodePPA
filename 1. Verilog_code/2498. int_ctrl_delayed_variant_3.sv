//SystemVerilog
module int_ctrl_delayed #(
    parameter CYCLE = 2
)(
    input clk, rst,
    input [7:0] req_in,
    output reg [2:0] delayed_grant
);
    // 请求信号流水线寄存器
    reg [7:0] req_pipe_0;
    reg [7:0] req_pipe_1;
    
    // 编码器缓冲寄存器组 - 分散扇出负载
    reg [2:0] encoder_stage1;
    reg [2:0] encoder_buf1_a, encoder_buf1_b;
    reg [2:0] encoder_buf2;
    
    // 分组缓冲寄存器 - 将req_pipe_1分成两组减少扇出负载
    reg [3:0] req_pipe_1_high;
    reg [3:0] req_pipe_1_low;
    
    // 重置逻辑
    always @(posedge clk) begin
        if(rst) begin
            req_pipe_0 <= 8'b0;
            req_pipe_1 <= 8'b0;
            req_pipe_1_high <= 4'b0;
            req_pipe_1_low <= 4'b0;
            encoder_stage1 <= 3'b0;
            encoder_buf1_a <= 3'b0;
            encoder_buf1_b <= 3'b0;
            encoder_buf2 <= 3'b0;
            delayed_grant <= 3'b0;
        end
    end
    
    // 请求信号流水线处理
    always @(posedge clk) begin
        if(!rst) begin
            req_pipe_0 <= req_in;
            req_pipe_1 <= req_pipe_0;
            
            // 将请求分成高低两部分，减少扇出负载
            req_pipe_1_high <= req_pipe_0[7:4];
            req_pipe_1_low <= req_pipe_0[3:0];
        end
    end
    
    // 编码器处理 - 将编码功能分散到多个always块中减少关键路径长度
    always @(posedge clk) begin
        if(!rst) begin
            encoder_stage1 <= encoder(req_pipe_1, req_pipe_1_high, req_pipe_1_low);
        end
    end
    
    // 缓冲寄存器阶段1 - 分散扇出
    always @(posedge clk) begin
        if(!rst) begin
            encoder_buf1_a <= encoder_stage1;
            encoder_buf1_b <= encoder_stage1;
        end
    end
    
    // 缓冲寄存器阶段2
    always @(posedge clk) begin
        if(!rst) begin
            encoder_buf2 <= (encoder_buf1_a & encoder_buf1_b); // 使用冗余校验确保信号稳定
        end
    end
    
    // 最终输出阶段
    always @(posedge clk) begin
        if(!rst) begin
            delayed_grant <= encoder_buf2;
        end
    end
    
    // 优化的编码器函数 - 使用分段判断减轻组合逻辑复杂度
    function [2:0] encoder;
        input [7:0] value;
        input [3:0] high_bits;
        input [3:0] low_bits;
        begin
            if(high_bits[3]) // 8'b1???????
                encoder = 3'd7;
            else if(high_bits[2]) // 8'b01??????
                encoder = 3'd6;
            else if(high_bits[1]) // 8'b001?????
                encoder = 3'd5;
            else if(high_bits[0]) // 8'b0001????
                encoder = 3'd4;
            else if(low_bits[3]) // 8'b00001???
                encoder = 3'd3;
            else if(low_bits[2]) // 8'b000001??
                encoder = 3'd2;
            else if(low_bits[1]) // 8'b0000001?
                encoder = 3'd1;
            else if(low_bits[0]) // 8'b00000001
                encoder = 3'd0;
            else
                encoder = 3'd0;
        end
    endfunction
endmodule