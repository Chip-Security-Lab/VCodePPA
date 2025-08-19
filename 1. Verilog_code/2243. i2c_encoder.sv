module i2c_encoder (
    input clk, start, stop,
    input [7:0] addr, data,
    output reg sda, scl,
    output ack
);
    // 使用参数替代enum类型
    parameter IDLE = 3'd0, START = 3'd1, ADDR = 3'd2, DATA = 3'd3, STOP = 3'd4;
    
    reg [2:0] state;
    reg [3:0] bit_cnt;
    reg ack_reg;
    
    always @(posedge clk) begin
        if (start) begin
            state <= START;
            bit_cnt <= 4'h0;
            ack_reg <= 1'b0;
        end else case(state)
            IDLE: begin
                scl <= 1'b1;
                sda <= 1'b1;
                if (start) state <= START;
            end
            START: begin 
                scl <= 1'b0; 
                sda <= 1'b0; 
                state <= ADDR; 
            end
            ADDR: begin
                if (bit_cnt < 8) begin
                    sda <= addr[7 - bit_cnt];
                    bit_cnt <= bit_cnt + 1;
                    scl <= ~scl; // 产生SCL脉冲
                end else begin
                    state <= DATA;
                    bit_cnt <= 4'h0;
                    ack_reg <= 1'b1; // 表示已发送地址
                end
            end
            DATA: begin
                if (bit_cnt < 8) begin
                    sda <= data[7 - bit_cnt];
                    bit_cnt <= bit_cnt + 1;
                    scl <= ~scl; // 产生SCL脉冲
                end else if (stop) begin
                    state <= STOP;
                    ack_reg <= 1'b1; // 表示已发送数据
                end else begin
                    bit_cnt <= 4'h0; // 准备下一个数据字节
                    ack_reg <= 1'b1;
                end
            end
            STOP: begin
                scl <= 1'b1;
                sda <= 1'b1;
                state <= IDLE;
            end
            default: state <= IDLE;
        endcase
    end
    
    assign ack = ack_reg;
endmodule