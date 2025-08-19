//SystemVerilog
module hamming_encoder_with_status(
    input clk, reset, enable,
    input [7:0] data_in,
    output reg [11:0] encoded_data,
    output reg busy, done
);
    // 状态定义
    localparam IDLE = 2'b00, 
               STAGE1 = 2'b01, 
               STAGE2 = 2'b10, 
               COMPLETE = 2'b11;
    
    reg [1:0] state;
    
    // 流水线阶段寄存器
    reg [7:0] data_stage1;
    reg [2:0] parity_stage1;
    reg [7:0] data_stage2;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            busy <= 0;
            done <= 0;
            encoded_data <= 0;
            data_stage1 <= 0;
            parity_stage1 <= 0;
            data_stage2 <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (enable) begin
                        state <= STAGE1;
                        busy <= 1;
                        done <= 0;
                        data_stage1 <= data_in;
                    end
                end
                
                STAGE1: begin
                    // 第一级流水线：计算奇偶校验位
                    parity_stage1[0] <= ^(data_stage1 & 8'b10101010);
                    parity_stage1[1] <= ^(data_stage1 & 8'b11001100);
                    parity_stage1[2] <= ^(data_stage1 & 8'b11110000);
                    data_stage2 <= data_stage1;
                    state <= STAGE2;
                end
                
                STAGE2: begin
                    // 第二级流水线：组装编码后的数据
                    encoded_data <= {data_stage2, 1'b0, parity_stage1};
                    state <= COMPLETE;
                end
                
                COMPLETE: begin
                    busy <= 0;
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule