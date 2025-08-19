//SystemVerilog
module hybrid_hamming_parity(
    input clk, rst_n,
    input [7:0] data,
    input valid_in,      // 发送方数据有效信号
    output ready_out,    // 接收方准备好接收信号
    output reg [15:0] encoded,
    output reg valid_out // 输出数据有效信号
);
    reg [11:0] hamming_code;
    reg [3:0] parity_bits;
    reg busy;
    
    // Ready信号 - 当模块不忙时可以接收新数据
    assign ready_out = !busy;
    
    // 定义状态变量
    reg [1:0] state;
    localparam IDLE = 2'b00,
               ENCODE = 2'b01,
               DONE = 2'b10;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hamming_code <= 12'b0;
            parity_bits <= 4'b0;
            encoded <= 16'b0;
            valid_out <= 1'b0;
            busy <= 1'b0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (valid_in) begin
                        busy <= 1'b1;
                        
                        // Hamming code for first 4 bits
                        hamming_code[0] <= data[0] ^ data[1] ^ data[3];
                        hamming_code[1] <= data[0] ^ data[2] ^ data[3];
                        hamming_code[2] <= data[0];
                        hamming_code[3] <= data[1] ^ data[2] ^ data[3];
                        hamming_code[4] <= data[1];
                        hamming_code[5] <= data[2];
                        hamming_code[6] <= data[3];
                        
                        // Simple parity for remaining 4 bits
                        parity_bits[0] <= ^data[7:4];
                        parity_bits[1] <= ^{data[7], data[6]};
                        parity_bits[2] <= ^{data[5], data[4]};
                        parity_bits[3] <= ^data[7:4];
                        
                        // Combine both codes
                        encoded <= {data[7:4], parity_bits, hamming_code[6:0]};
                        
                        // 设置输出有效信号
                        valid_out <= 1'b1;
                        state <= DONE;
                    end
                end
                
                DONE: begin
                    // 数据已生成并发送，清除状态
                    valid_out <= 1'b0;
                    busy <= 1'b0;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule