//SystemVerilog
module duty_cycle_controller(
    input wire clock_in,
    input wire reset,
    input wire [3:0] duty_cycle, // 0-15 (0%-93.75%)
    output reg clock_out
);
    reg [3:0] count_reg;
    reg [3:0] count_buf1;
    reg [3:0] count_buf2;
    reg clock_out_next;

    // 主计数寄存器（扁平化控制流）
    always @(posedge clock_in) begin
        if (reset)
            count_reg <= 4'd0;
        else if (count_reg < 4'd15)
            count_reg <= count_reg + 1'b1;
        else
            count_reg <= 4'd0;
    end

    // 第一级缓冲寄存器（扁平化控制流）
    always @(posedge clock_in) begin
        if (reset)
            count_buf1 <= 4'd0;
        else
            count_buf1 <= count_reg;
    end

    // 第二级缓冲寄存器（扁平化控制流）
    always @(posedge clock_in) begin
        if (reset)
            count_buf2 <= 4'd0;
        else
            count_buf2 <= count_buf1;
    end

    // 输出逻辑缓冲（扁平化控制流）
    always @(posedge clock_in) begin
        if (reset)
            clock_out_next <= 1'b0;
        else if (count_buf2 < duty_cycle)
            clock_out_next <= 1'b1;
        else
            clock_out_next <= 1'b0;
    end

    // 输出寄存器（扁平化控制流）
    always @(posedge clock_in) begin
        if (reset)
            clock_out <= 1'b0;
        else
            clock_out <= clock_out_next;
    end

endmodule