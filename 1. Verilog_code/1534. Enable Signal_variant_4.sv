//SystemVerilog
// IEEE 1364-2005 Verilog标准
// 顶层模块
module enabled_shadow_reg #(
    parameter DATA_WIDTH = 12
)(
    input wire clock,
    input wire reset_n,
    input wire enable,
    input wire [DATA_WIDTH-1:0] data_input,
    input wire shadow_capture,
    output wire [DATA_WIDTH-1:0] shadow_output
);
    // 内部连线
    wire [DATA_WIDTH-1:0] data_reg_value;
    
    // 主数据寄存器子模块实例化
    main_data_register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) main_reg_inst (
        .clock(clock),
        .reset_n(reset_n),
        .enable(enable),
        .data_input(data_input),
        .data_output(data_reg_value)
    );
    
    // 影子寄存器子模块实例化
    shadow_register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) shadow_reg_inst (
        .clock(clock),
        .reset_n(reset_n),
        .enable(enable),
        .shadow_capture(shadow_capture),
        .data_input(data_reg_value),
        .shadow_output(shadow_output)
    );
endmodule

// 主数据寄存器子模块
module main_data_register #(
    parameter DATA_WIDTH = 12
)(
    input wire clock,
    input wire reset_n,
    input wire enable,
    input wire [DATA_WIDTH-1:0] data_input,
    output reg [DATA_WIDTH-1:0] data_output
);
    // 主寄存器逻辑，带使能控制
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            data_output <= {DATA_WIDTH{1'b0}};
        else if (enable)
            data_output <= data_input;
    end
endmodule

// 影子寄存器子模块
module shadow_register #(
    parameter DATA_WIDTH = 12
)(
    input wire clock,
    input wire reset_n,
    input wire enable,
    input wire shadow_capture,
    input wire [DATA_WIDTH-1:0] data_input,
    output reg [DATA_WIDTH-1:0] shadow_output
);
    // 影子寄存器捕获逻辑
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            shadow_output <= {DATA_WIDTH{1'b0}};
        else if (shadow_capture && enable)
            shadow_output <= data_input;
    end
endmodule