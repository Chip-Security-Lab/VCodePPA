//SystemVerilog
// 顶层模块
module generate_mux #(
    parameter NUM_INPUTS = 16,
    parameter DATA_WIDTH = 8
)(
    input [DATA_WIDTH-1:0] data_in [0:NUM_INPUTS-1],
    input [$clog2(NUM_INPUTS)-1:0] sel,
    output [DATA_WIDTH-1:0] data_out
);
    // 中间连接信号
    wire [DATA_WIDTH-1:0] mux_stage [0:NUM_INPUTS-1];
    
    // 实例化选择器子模块
    selector #(
        .NUM_INPUTS(NUM_INPUTS),
        .DATA_WIDTH(DATA_WIDTH)
    ) selector_inst (
        .data_in(data_in),
        .sel(sel),
        .mux_out(mux_stage)
    );
    
    // 实例化归约子模块
    or_reducer #(
        .NUM_INPUTS(NUM_INPUTS),
        .DATA_WIDTH(DATA_WIDTH)
    ) or_reducer_inst (
        .mux_in(mux_stage),
        .data_out(data_out)
    );
endmodule

// 选择器子模块 - 处理选择逻辑
module selector #(
    parameter NUM_INPUTS = 16,
    parameter DATA_WIDTH = 8
)(
    input [DATA_WIDTH-1:0] data_in [0:NUM_INPUTS-1],
    input [$clog2(NUM_INPUTS)-1:0] sel,
    output [DATA_WIDTH-1:0] mux_out [0:NUM_INPUTS-1]
);
    genvar i;
    generate
        for (i = 0; i < NUM_INPUTS; i = i + 1) begin: mux_gen
            assign mux_out[i] = (sel == i) ? data_in[i] : {DATA_WIDTH{1'b0}};
        end
    endgenerate
endmodule

// 或归约子模块 - 处理归约逻辑
module or_reducer #(
    parameter NUM_INPUTS = 16,
    parameter DATA_WIDTH = 8
)(
    input [DATA_WIDTH-1:0] mux_in [0:NUM_INPUTS-1],
    output [DATA_WIDTH-1:0] data_out
);
    reg [DATA_WIDTH-1:0] result;
    
    always @(*) begin
        result = {DATA_WIDTH{1'b0}};
        for (int j = 0; j < NUM_INPUTS; j = j + 1) begin
            result = result | mux_in[j];
        end
    end
    
    assign data_out = result;
endmodule