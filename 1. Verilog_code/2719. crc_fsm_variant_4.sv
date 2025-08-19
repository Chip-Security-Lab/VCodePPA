//SystemVerilog
module crc_fsm (
    input clk, start, rst,
    input [7:0] data,
    output reg [15:0] crc,
    output done
);
    // 将枚举类型改为参数定义
    parameter IDLE = 0, CALC = 1, FINISH = 2;
    reg [1:0] state;
    
    // 实现CRC计算函数 - 循环已展开
    function [15:0] crc_calculate;
        input [7:0] data;
        input [15:0] crc_in;
        reg [15:0] crc_temp;
        begin
            // 位0处理
            crc_temp = crc_in;
            if ((data[0] ^ crc_temp[15]) == 1'b1)
                crc_temp = {crc_temp[14:0], 1'b0} ^ 16'h1021;
            else
                crc_temp = {crc_temp[14:0], 1'b0};
                
            // 位1处理
            if ((data[1] ^ crc_temp[15]) == 1'b1)
                crc_temp = {crc_temp[14:0], 1'b0} ^ 16'h1021;
            else
                crc_temp = {crc_temp[14:0], 1'b0};
                
            // 位2处理
            if ((data[2] ^ crc_temp[15]) == 1'b1)
                crc_temp = {crc_temp[14:0], 1'b0} ^ 16'h1021;
            else
                crc_temp = {crc_temp[14:0], 1'b0};
                
            // 位3处理
            if ((data[3] ^ crc_temp[15]) == 1'b1)
                crc_temp = {crc_temp[14:0], 1'b0} ^ 16'h1021;
            else
                crc_temp = {crc_temp[14:0], 1'b0};
                
            // 位4处理
            if ((data[4] ^ crc_temp[15]) == 1'b1)
                crc_temp = {crc_temp[14:0], 1'b0} ^ 16'h1021;
            else
                crc_temp = {crc_temp[14:0], 1'b0};
                
            // 位5处理
            if ((data[5] ^ crc_temp[15]) == 1'b1)
                crc_temp = {crc_temp[14:0], 1'b0} ^ 16'h1021;
            else
                crc_temp = {crc_temp[14:0], 1'b0};
                
            // 位6处理
            if ((data[6] ^ crc_temp[15]) == 1'b1)
                crc_temp = {crc_temp[14:0], 1'b0} ^ 16'h1021;
            else
                crc_temp = {crc_temp[14:0], 1'b0};
                
            // 位7处理
            if ((data[7] ^ crc_temp[15]) == 1'b1)
                crc_temp = {crc_temp[14:0], 1'b0} ^ 16'h1021;
            else
                crc_temp = {crc_temp[14:0], 1'b0};
                
            crc_calculate = crc_temp;
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