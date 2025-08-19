//SystemVerilog
module table_crc16(
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    input wire req,
    output reg ack,
    output reg [15:0] crc_result
);
    reg [15:0] crc_table [0:255];
    reg [15:0] crc_temp;
    reg req_prev;
    reg processing;
    reg [7:0] table_index;
    reg [15:0] crc_shifted;
    reg [15:0] crc_xor;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            crc_result <= 16'hFFFF;
            ack <= 1'b0;
            req_prev <= 1'b0;
            processing <= 1'b0;
            table_index <= 8'h0;
            crc_shifted <= 16'h0;
            crc_xor <= 16'h0;
        end else begin
            req_prev <= req;
            
            // 预计算常用值
            crc_shifted <= crc_result >> 8;
            crc_xor <= crc_result ^ {8'h00, data_in};
            table_index <= crc_xor[7:0];
            
            // 状态机逻辑优化
            case ({req, req_prev, processing, ack})
                4'b1000: begin  // 新请求到达
                    processing <= 1'b1;
                    crc_result <= crc_shifted ^ crc_table[table_index];
                    ack <= 1'b1;
                end
                4'b0011: begin  // 处理完成
                    ack <= 1'b0;
                    processing <= 1'b0;
                end
                default: begin
                    // 保持当前状态
                end
            endcase
        end
    end
endmodule