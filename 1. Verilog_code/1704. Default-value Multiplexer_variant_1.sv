//SystemVerilog
// 顶层模块
module default_value_mux #(
    parameter WIDTH = 12,
    parameter DEFAULT_VAL = {WIDTH{1'b1}}
)(
    input [WIDTH-1:0] data_a, data_b, data_c,
    input [1:0] mux_select,
    input use_default,
    output [WIDTH-1:0] mux_result
);
    wire [WIDTH-1:0] primary_selected;
    
    // 实例化数据选择器子模块
    data_selector #(
        .WIDTH(WIDTH),
        .DEFAULT_VAL(DEFAULT_VAL)
    ) primary_selector (
        .data_a(data_a),
        .data_b(data_b),
        .data_c(data_c),
        .select(mux_select),
        .selected_data(primary_selected)
    );
    
    // 实例化默认值控制子模块
    default_controller #(
        .WIDTH(WIDTH),
        .DEFAULT_VAL(DEFAULT_VAL)
    ) final_selector (
        .data_in(primary_selected),
        .use_default(use_default),
        .data_out(mux_result)
    );
endmodule

// 数据选择器子模块
module data_selector #(
    parameter WIDTH = 12,
    parameter DEFAULT_VAL = {WIDTH{1'b1}}
)(
    input [WIDTH-1:0] data_a, data_b, data_c,
    input [1:0] select,
    output reg [WIDTH-1:0] selected_data
);
    wire [WIDTH-1:0] sel_a, sel_b, sel_c;
    wire [1:0] sel_valid;
    
    // 条件选择逻辑
    assign sel_valid = (select == 2'b00) ? 2'b01 : 
                      (select == 2'b01) ? 2'b10 :
                      (select == 2'b10) ? 2'b11 : 2'b00;
                      
    assign sel_a = {WIDTH{sel_valid[0]}} & data_a;
    assign sel_b = {WIDTH{sel_valid[1]}} & data_b;
    assign sel_c = {WIDTH{sel_valid[1] & sel_valid[0]}} & data_c;
    
    // 条件求和
    always @(*) begin
        selected_data = sel_a | sel_b | sel_c;
        if (sel_valid == 2'b00)
            selected_data = DEFAULT_VAL;
    end
endmodule

// 默认值控制子模块
module default_controller #(
    parameter WIDTH = 12,
    parameter DEFAULT_VAL = {WIDTH{1'b1}}
)(
    input [WIDTH-1:0] data_in,
    input use_default,
    output [WIDTH-1:0] data_out
);
    wire [WIDTH-1:0] default_mask;
    assign default_mask = {WIDTH{use_default}};
    assign data_out = (default_mask & DEFAULT_VAL) | (~default_mask & data_in);
endmodule