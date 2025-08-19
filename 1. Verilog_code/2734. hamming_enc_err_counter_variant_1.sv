//SystemVerilog
module hamming_enc_err_counter(
    input clk, rst,
    input [3:0] data_in,
    input valid_in,
    input error_inject,
    output reg ready_out,
    output reg [6:0] encoded,
    output reg valid_out,
    output reg [7:0] error_count
);

    reg [3:0] data_reg;
    reg error_reg;
    
    // Valid-Ready握手状态
    localparam IDLE = 1'b0;
    localparam PROCESSING = 1'b1;
    reg state;

    // 主状态机 - 处理输入和输出握手
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            encoded <= 7'b0;
            error_count <= 8'b0;
            ready_out <= 1'b1; // 初始状态为ready
            valid_out <= 1'b0;
            data_reg <= 4'b0;
            error_reg <= 1'b0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    // 输入握手 - 当valid_in为高且ready_out为高时接收数据
                    if (valid_in && ready_out) begin
                        data_reg <= data_in;
                        error_reg <= error_inject;
                        ready_out <= 1'b0; // 暂时不接收新数据
                        state <= PROCESSING;
                    end
                end
                
                PROCESSING: begin
                    // 数据处理和编码
                    encoded[0] <= data_reg[0] ^ data_reg[1] ^ data_reg[3];
                    encoded[1] <= data_reg[0] ^ data_reg[2] ^ data_reg[3];
                    encoded[2] <= data_reg[0];
                    encoded[3] <= data_reg[1] ^ data_reg[2] ^ data_reg[3];
                    encoded[4] <= data_reg[1];
                    encoded[5] <= data_reg[2];
                    encoded[6] <= data_reg[3];
                    
                    // 错误注入
                    if (error_reg) begin
                        encoded[0] <= ~(data_reg[0] ^ data_reg[1] ^ data_reg[3]);
                        error_count <= error_count + 1;
                    end
                    
                    valid_out <= 1'b1; // 数据已处理完成，可以输出
                    ready_out <= 1'b1; // 准备接收下一个数据
                    state <= IDLE;
                end
            endcase
            
            // 当下游接收到数据后，清除valid信号
            if (valid_out && !ready_out) begin
                valid_out <= 1'b0;
            end
        end
    end
endmodule