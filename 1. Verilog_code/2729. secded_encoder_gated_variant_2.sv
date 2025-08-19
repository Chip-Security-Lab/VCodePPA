//SystemVerilog
module secded_encoder_req_ack(
    input clk, rst,
    input req,
    input [3:0] data,
    output reg ack,
    output reg [7:0] code // 7 bits + overall parity
);
    reg req_r;
    reg processing;
    wire req_edge;
    reg [6:0] hamming_code;
    
    // 检测请求信号的上升沿
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            req_r <= 1'b0;
        end else begin
            req_r <= req;
        end
    end
    
    assign req_edge = req & ~req_r;
    
    // 状态控制和数据处理
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            processing <= 1'b0;
            ack <= 1'b0;
            hamming_code <= 7'b0;
            code <= 8'b0;
        end else begin
            if (req_edge && !processing) begin
                processing <= 1'b1;
                
                // 编码逻辑
                hamming_code[0] <= data[0] ^ data[1] ^ data[3];
                hamming_code[1] <= data[0] ^ data[2] ^ data[3];
                hamming_code[2] <= data[0];
                hamming_code[3] <= data[1] ^ data[2] ^ data[3];
                hamming_code[4] <= data[1];
                hamming_code[5] <= data[2];
                hamming_code[6] <= data[3];
                code <= {^{data[0] ^ data[1] ^ data[3], 
                          data[0] ^ data[2] ^ data[3], 
                          data[0], 
                          data[1] ^ data[2] ^ data[3], 
                          data[1], 
                          data[2], 
                          data[3]}, 
                         data[0] ^ data[1] ^ data[3], 
                         data[0] ^ data[2] ^ data[3], 
                         data[0], 
                         data[1] ^ data[2] ^ data[3], 
                         data[1], 
                         data[2], 
                         data[3]}; // 优化关键路径
                
                ack <= 1'b1;
            end else if (!req && processing) begin
                processing <= 1'b0;
                ack <= 1'b0;
            end
        end
    end
endmodule