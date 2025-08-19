//SystemVerilog
// 顶层模块
module shadow_reg_pipeline #(
    parameter DW = 8
)(
    input wire clk,
    input wire en,
    input wire [DW-1:0] data_in,
    output wire [DW-1:0] data_out
);
    // 内部连线
    wire [DW-1:0] shadow_stage_out;
    wire [DW-1:0] pipe_stage_out;
    
    // 实例化输入阶段子模块
    input_stage #(
        .DW(DW)
    ) u_input_stage (
        .clk(clk),
        .en(en),
        .data_in(data_in),
        .shadow_out(shadow_stage_out)
    );
    
    // 实例化管道阶段子模块
    pipeline_stage #(
        .DW(DW)
    ) u_pipeline_stage (
        .clk(clk),
        .shadow_in(shadow_stage_out),
        .pipe_out(pipe_stage_out)
    );
    
    // 实例化输出阶段子模块
    output_stage #(
        .DW(DW)
    ) u_output_stage (
        .clk(clk),
        .pipe_in(pipe_stage_out),
        .data_out(data_out)
    );
    
endmodule

// 输入阶段子模块
module input_stage #(
    parameter DW = 8
)(
    input wire clk,
    input wire en,
    input wire [DW-1:0] data_in,
    output reg [DW-1:0] shadow_out
);
    always @(posedge clk) begin
        if(en) shadow_out <= data_in;
    end
endmodule

// 管道阶段子模块
module pipeline_stage #(
    parameter DW = 8
)(
    input wire clk,
    input wire [DW-1:0] shadow_in,
    output reg [DW-1:0] pipe_out
);
    always @(posedge clk) begin
        pipe_out <= shadow_in;
    end
endmodule

// 输出阶段子模块
module output_stage #(
    parameter DW = 8
)(
    input wire clk,
    input wire [DW-1:0] pipe_in,
    output reg [DW-1:0] data_out
);
    always @(posedge clk) begin
        data_out <= pipe_in;
    end
endmodule