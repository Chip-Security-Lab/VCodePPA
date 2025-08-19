//SystemVerilog
// 顶层模块
module mux_d_latch_top (
    input wire [3:0] d_inputs,
    input wire [1:0] select,
    input wire enable,
    output wire q
);
    // 内部信号
    wire selected_data;
    
    // 实例化多路选择器子模块
    mux_4to1 mux_inst (
        .d_inputs(d_inputs),
        .select(select),
        .selected_data(selected_data)
    );
    
    // 实例化锁存器子模块
    d_latch latch_inst (
        .d(selected_data),
        .enable(enable),
        .q(q)
    );
endmodule

// 4选1多路选择器子模块
module mux_4to1 (
    input wire [3:0] d_inputs,
    input wire [1:0] select,
    output reg selected_data
);
    always @* begin
        case(select)
            2'b00: selected_data = d_inputs[0];
            2'b01: selected_data = d_inputs[1];
            2'b10: selected_data = d_inputs[2];
            2'b11: selected_data = d_inputs[3];
            default: selected_data = d_inputs[0];
        endcase
    end
endmodule

// D锁存器子模块
module d_latch (
    input wire d,
    input wire enable,
    output reg q
);
    always @* begin
        if (enable)
            q = d;
    end
endmodule