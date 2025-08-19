//SystemVerilog
module float_rot #(parameter EXP=5, parameter MANT=10)(
    input  [EXP+MANT:0] in,
    input  [4:0] sh,
    output reg [EXP+MANT:0] out
);
    reg [MANT:0] mantissa_input;
    reg [2*MANT+1:0] mantissa_double;
    reg [2*MANT+1:0] mantissa_double_shifted_a;
    reg [2*MANT+1:0] mantissa_double_shifted_b;
    reg [MANT:0] mantissa_approx;
    reg [MANT:0] rotated_mantissa;

    // 桶形移位器：多级多路复用器实现移位
    function [2*MANT+1:0] barrel_shifter_right;
        input [2*MANT+1:0] data_in;
        input [4:0] shift_amt;
        integer i;
        reg [2*MANT+1:0] s [0:5];
    begin
        s[0] = data_in;
        // 16位移位
        s[1] = shift_amt[4] ? {16'b0, s[0][2*MANT+1:16]} : s[0];
        // 8位移位
        s[2] = shift_amt[3] ? {8'b0, s[1][2*MANT+1:8]} : s[1];
        // 4位移位
        s[3] = shift_amt[2] ? {4'b0, s[2][2*MANT+1:4]} : s[2];
        // 2位移位
        s[4] = shift_amt[1] ? {2'b0, s[3][2*MANT+1:2]} : s[3];
        // 1位移位
        s[5] = shift_amt[0] ? {1'b0, s[4][2*MANT+1:1]} : s[4];
        barrel_shifter_right = s[5];
    end
    endfunction

    // 桶形移位器用于两个不同的移位量
    function [2*MANT+1:0] barrel_shifter_right_sub;
        input [2*MANT+1:0] data_in;
        input [4:0] shift_amt;
        input [4:0] offset;
    begin
        barrel_shifter_right_sub = barrel_shifter_right(data_in, shift_amt - offset);
    end
    endfunction

    always @* begin
        mantissa_input = in[MANT:0];
        mantissa_double = {mantissa_input, mantissa_input};

        // 分段处理桶形移位
        if (sh[4:3] == 2'b00) begin // sh = 0~7
            mantissa_double_shifted_a = barrel_shifter_right(mantissa_double, sh);
            mantissa_approx = mantissa_double_shifted_a[MANT:0];
        end else if (sh[4:3] == 2'b01) begin // sh = 8~15
            mantissa_double_shifted_a = barrel_shifter_right_sub(mantissa_double, sh, 5'd8);
            mantissa_double_shifted_b = barrel_shifter_right_sub(mantissa_double, sh, 5'd7);
            mantissa_approx = ((mantissa_double_shifted_a[MANT:0] + mantissa_double_shifted_b[MANT:0]) >> 1);
        end else if (sh[4:3] == 2'b10) begin // sh = 16~23
            mantissa_double_shifted_a = barrel_shifter_right_sub(mantissa_double, sh, 5'd16);
            mantissa_double_shifted_b = barrel_shifter_right_sub(mantissa_double, sh, 5'd15);
            mantissa_approx = mantissa_double_shifted_a[MANT:0] - mantissa_double_shifted_b[MANT:0];
        end else begin // sh = 24~31
            mantissa_double_shifted_a = barrel_shifter_right_sub(mantissa_double, sh, 5'd16);
            mantissa_approx = mantissa_double_shifted_a[MANT:0];
        end

        rotated_mantissa = mantissa_approx[MANT:1];

        out = {in[EXP+MANT], in[EXP+MANT-1:MANT], rotated_mantissa};
    end
endmodule