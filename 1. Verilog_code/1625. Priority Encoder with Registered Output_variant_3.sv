//SystemVerilog
module priority_encoder_reg (
    input clk,
    input [7:0] requests,
    output reg [2:0] grant_id,
    output reg valid
);

    // 请求信号缓冲寄存器
    reg [7:0] requests_buf;
    reg [7:0] requests_buf2;
    
    // 中间优先级编码结果寄存器
    reg [2:0] grant_id_temp;
    reg valid_temp;

    // 第一级请求信号缓冲
    always @(posedge clk) begin
        requests_buf <= requests;
    end

    // 第二级请求信号缓冲
    always @(posedge clk) begin
        requests_buf2 <= requests_buf;
    end

    // 有效信号生成
    always @(posedge clk) begin
        valid_temp <= |requests_buf2;
    end

    // 优先级编码逻辑
    always @(posedge clk) begin
        if (requests_buf2[0]) grant_id_temp <= 3'd0;
        else if (requests_buf2[1]) grant_id_temp <= 3'd1;
        else if (requests_buf2[2]) grant_id_temp <= 3'd2;
        else if (requests_buf2[3]) grant_id_temp <= 3'd3;
        else if (requests_buf2[4]) grant_id_temp <= 3'd4;
        else if (requests_buf2[5]) grant_id_temp <= 3'd5;
        else if (requests_buf2[6]) grant_id_temp <= 3'd6;
        else if (requests_buf2[7]) grant_id_temp <= 3'd7;
        else grant_id_temp <= 3'd0;
    end

    // 输出寄存器
    always @(posedge clk) begin
        grant_id <= grant_id_temp;
        valid <= valid_temp;
    end

endmodule