//SystemVerilog
// 顶层模块
module bin2thermometer #(parameter BIN_WIDTH = 3) (
    input  [BIN_WIDTH-1:0] bin_input,
    output [(2**BIN_WIDTH)-2:0] therm_output
);
    // 实例化比较器子模块
    comparator_array #(
        .BIN_WIDTH(BIN_WIDTH)
    ) comp_inst (
        .binary_value(bin_input),
        .thermometer_code(therm_output)
    );
endmodule

// 比较器阵列子模块
module comparator_array #(parameter BIN_WIDTH = 3) (
    input  [BIN_WIDTH-1:0] binary_value,
    output [(2**BIN_WIDTH)-2:0] thermometer_code
);
    // 实例化比较逻辑子模块
    comparison_logic #(
        .THERM_WIDTH(2**BIN_WIDTH-1)
    ) comp_logic_inst (
        .bin_val(binary_value),
        .therm_out(thermometer_code)
    );
endmodule

// 比较逻辑子模块
module comparison_logic #(parameter THERM_WIDTH = 7) (
    input  [$clog2(THERM_WIDTH+1)-1:0] bin_val,
    output [THERM_WIDTH-1:0] therm_out
);
    // 并行比较生成温度计码，无需for循环
    genvar i;
    generate
        for (i = 0; i < THERM_WIDTH; i = i + 1) begin : gen_comp
            assign therm_out[i] = (i < bin_val);
        end
    endgenerate
endmodule