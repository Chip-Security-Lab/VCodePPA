//SystemVerilog
// 顶层模块
module struct_unpack #(
    parameter TOTAL_W = 32,
    parameter FIELD_N = 4
) (
    input [TOTAL_W-1:0] packed_data,
    input [$clog2(FIELD_N)-1:0] select,
    output [TOTAL_W/FIELD_N-1:0] unpacked
);
    // 本地参数
    localparam FIELD_W = TOTAL_W / FIELD_N;
    
    // 内部连线
    wire [FIELD_N-1:0][FIELD_W-1:0] data_fields;
    wire [FIELD_N-1:0] valid_fields;
    
    // 子模块实例化
    field_splitter #(
        .TOTAL_W(TOTAL_W),
        .FIELD_N(FIELD_N)
    ) splitter_inst (
        .packed_data(packed_data),
        .data_fields(data_fields)
    );
    
    field_validator #(
        .FIELD_N(FIELD_N),
        .FIELD_W(FIELD_W)
    ) validator_inst (
        .data_fields(data_fields),
        .valid_fields(valid_fields)
    );
    
    field_selector #(
        .FIELD_N(FIELD_N),
        .FIELD_W(FIELD_W)
    ) selector_inst (
        .data_fields(data_fields),
        .valid_fields(valid_fields),
        .select(select),
        .unpacked(unpacked)
    );
    
endmodule

// 字段分割子模块
module field_splitter #(
    parameter TOTAL_W = 32,
    parameter FIELD_N = 4
) (
    input [TOTAL_W-1:0] packed_data,
    output [FIELD_N-1:0][FIELD_W-1:0] data_fields
);
    // 本地参数
    localparam FIELD_W = TOTAL_W / FIELD_N;
    
    // 将输入数据分割成多个字段
    genvar i;
    generate
        for (i = 0; i < FIELD_N; i = i + 1) begin : split_gen
            assign data_fields[i] = packed_data[i*FIELD_W +: FIELD_W];
        end
    endgenerate
    
endmodule

// 字段验证子模块
module field_validator #(
    parameter FIELD_N = 4,
    parameter FIELD_W = 8
) (
    input [FIELD_N-1:0][FIELD_W-1:0] data_fields,
    output [FIELD_N-1:0] valid_fields
);
    // 验证每个字段的有效性
    genvar i;
    generate
        for (i = 0; i < FIELD_N; i = i + 1) begin : valid_gen
            assign valid_fields[i] = |data_fields[i]; // 检查字段是否非零
        end
    endgenerate
    
endmodule

// 字段选择子模块
module field_selector #(
    parameter FIELD_N = 4,
    parameter FIELD_W = 8
) (
    input [FIELD_N-1:0][FIELD_W-1:0] data_fields,
    input [FIELD_N-1:0] valid_fields,
    input [$clog2(FIELD_N)-1:0] select,
    output reg [FIELD_W-1:0] unpacked
);
    // 基于选择信号和有效性输出对应字段
    always @(*) begin
        if (valid_fields[select])
            unpacked = data_fields[select];
        else
            unpacked = {FIELD_W{1'b0}}; // 无效字段输出全0
    end
    
endmodule