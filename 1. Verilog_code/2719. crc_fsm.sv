module crc_fsm (
    input clk, start, rst,
    input [7:0] data,
    output reg [15:0] crc,
    output done
);
    // 将枚举类型改为参数定义
    parameter IDLE = 0, CALC = 1, FINISH = 2;
    reg [1:0] state;
    
    // 实现CRC计算函数
    function [15:0] crc_calculate;
        input [7:0] data;
        input [15:0] crc_in;
        reg [15:0] crc_out;
        integer i;
        begin
            crc_out = crc_in;
            for (i = 0; i < 8; i = i + 1) begin
                if ((data[i] ^ crc_out[15]) == 1'b1)
                    crc_out = {crc_out[14:0], 1'b0} ^ 16'h1021;
                else
                    crc_out = {crc_out[14:0], 1'b0};
            end
            crc_calculate = crc_out;
        end
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            crc <= 16'hFFFF;
        end else case(state)
            IDLE: if (start) state <= CALC;
            CALC: begin
                crc <= crc_calculate(data, crc);
                state <= FINISH;
            end
            FINISH: state <= IDLE;
            default: state <= IDLE;
        endcase
    end

    assign done = (state == FINISH);
endmodule