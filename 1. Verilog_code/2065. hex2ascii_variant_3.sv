//SystemVerilog
// Top-level module: hex2ascii
module hex2ascii (
    input wire [3:0] hex_in,
    output wire [7:0] ascii_out
);

    wire [7:0] numeric_ascii;
    wire [7:0] alpha_ascii;
    wire       is_numeric;

    // 子模块：判断输入是否为数字（0-9）
    hex_is_numeric u_hex_is_numeric (
        .hex_value    (hex_in),
        .is_numeric   (is_numeric)
    );

    // 子模块：生成数字的ASCII码
    hex_numeric_ascii u_hex_numeric_ascii (
        .hex_value   (hex_in),
        .ascii_code  (numeric_ascii)
    );

    // 子模块：生成字母的ASCII码（A-F）
    hex_alpha_ascii u_hex_alpha_ascii (
        .hex_value   (hex_in),
        .ascii_code  (alpha_ascii)
    );

    // 子模块：选择输出
    hex_ascii_mux u_hex_ascii_mux (
        .is_numeric  (is_numeric),
        .numeric_ascii (numeric_ascii),
        .alpha_ascii  (alpha_ascii),
        .ascii_out   (ascii_out)
    );

endmodule

// 子模块：判断输入是否为数字（0-9）
module hex_is_numeric (
    input  wire [3:0] hex_value,
    output wire       is_numeric
);
    assign is_numeric = (hex_value <= 4'd9) ? 1'b1 : 1'b0;
endmodule

// 子模块：生成数字的ASCII码
module hex_numeric_ascii (
    input  wire [3:0] hex_value,
    output wire [7:0] ascii_code
);
    assign ascii_code = {4'b0011, hex_value}; // '0' + hex_value
endmodule

// 子模块：生成字母的ASCII码（A-F）
module hex_alpha_ascii (
    input  wire [3:0] hex_value,
    output wire [7:0] ascii_code
);
    assign ascii_code = {4'b0100, hex_value} + 8'h27; // 'A' + (hex_value - 10)
endmodule

// 子模块：根据is_numeric选择输出
module hex_ascii_mux (
    input  wire       is_numeric,
    input  wire [7:0] numeric_ascii,
    input  wire [7:0] alpha_ascii,
    output wire [7:0] ascii_out
);
    assign ascii_out = is_numeric ? numeric_ascii : alpha_ascii;
endmodule