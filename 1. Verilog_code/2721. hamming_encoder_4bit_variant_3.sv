//SystemVerilog
module hamming_encoder_4bit(
    input clk, rst_n,
    input req,
    output reg ack,
    input [3:0] data_in,
    output reg [6:0] encoded_out
);
    reg req_prev;
    wire req_edge;
    
    // 请求边沿检测逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_prev <= 1'b0;
        end
        else begin
            req_prev <= req;
        end
    end
    
    // 生成上升沿脉冲信号
    assign req_edge = req && !req_prev;
    
    // 握手信号控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ack <= 1'b0;
        end
        else if (req_edge) begin
            ack <= 1'b1;
        end
        else if (!req) begin
            ack <= 1'b0;
        end
    end
    
    // 校验位生成逻辑 (P1, P2, P4)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            encoded_out[0] <= 1'b0; // P1
            encoded_out[1] <= 1'b0; // P2
            encoded_out[3] <= 1'b0; // P4
        end
        else if (req_edge) begin
            encoded_out[0] <= data_in[0] ^ data_in[1] ^ data_in[3]; // P1
            encoded_out[1] <= data_in[0] ^ data_in[2] ^ data_in[3]; // P2
            encoded_out[3] <= data_in[1] ^ data_in[2] ^ data_in[3]; // P4
        end
    end
    
    // 数据位映射逻辑 (D3, D5, D6, D7)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            encoded_out[2] <= 1'b0; // D3
            encoded_out[4] <= 1'b0; // D5
            encoded_out[5] <= 1'b0; // D6
            encoded_out[6] <= 1'b0; // D7
        end
        else if (req_edge) begin
            encoded_out[2] <= data_in[0]; // D3 = D1
            encoded_out[4] <= data_in[1]; // D5 = D2
            encoded_out[5] <= data_in[2]; // D6 = D3
            encoded_out[6] <= data_in[3]; // D7 = D4
        end
    end
endmodule