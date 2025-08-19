//SystemVerilog
module ring_counter_preset (
    input wire clk,
    input wire rst_n,
    input wire load,
    input wire in_valid,
    input wire [3:0] preset_val,
    output reg [3:0] out,
    output reg out_valid
);

    // 流水线阶段信号
    wire [3:0] stage1_data_next, stage2_data_next;
    wire stage1_valid_next, stage2_valid_next;
    wire stage1_load_next, stage2_load_next;
    wire [3:0] stage1_preset_next, stage2_preset_next;
    
    reg [3:0] stage1_data, stage2_data;
    reg stage1_valid, stage2_valid;
    reg stage1_load, stage2_load;
    reg [3:0] stage1_preset, stage2_preset;

    // 流水线阶段1数据计算
    assign stage1_data_next = out;
    assign stage1_valid_next = in_valid;
    assign stage1_load_next = load;
    assign stage1_preset_next = preset_val;

    // 流水线阶段2数据计算
    assign stage2_data_next = stage1_load ? stage1_preset : {stage1_data[0], stage1_data[3:1]};
    assign stage2_valid_next = stage1_valid;
    assign stage2_load_next = stage1_load;
    assign stage2_preset_next = stage1_preset;

    // 实例化流水线寄存器模块
    pipeline_stage #(
        .DATA_WIDTH(4)
    ) stage1 (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(stage1_data_next),
        .valid_in(stage1_valid_next),
        .load_in(stage1_load_next),
        .preset_in(stage1_preset_next),
        .enable(in_valid),
        .default_data(4'b0001),
        .data_out(stage1_data),
        .valid_out(stage1_valid),
        .load_out(stage1_load),
        .preset_out(stage1_preset)
    );

    pipeline_stage #(
        .DATA_WIDTH(4)
    ) stage2 (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(stage2_data_next),
        .valid_in(stage2_valid_next),
        .load_in(stage2_load_next),
        .preset_in(stage2_preset_next),
        .enable(stage1_valid),
        .default_data(4'b0001),
        .data_out(stage2_data),
        .valid_out(stage2_valid),
        .load_out(stage2_load),
        .preset_out(stage2_preset)
    );

    // 输出阶段 (简化版的流水线阶段)
    output_stage #(
        .DATA_WIDTH(4)
    ) output_reg (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(stage2_data),
        .valid_in(stage2_valid),
        .enable(stage2_valid),
        .default_data(4'b0001),
        .data_out(out),
        .valid_out(out_valid)
    );

endmodule

// 可重用的流水线寄存器模块
module pipeline_stage #(
    parameter DATA_WIDTH = 4
)(
    input wire clk,
    input wire rst_n,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire valid_in,
    input wire load_in,
    input wire [DATA_WIDTH-1:0] preset_in,
    input wire enable,
    input wire [DATA_WIDTH-1:0] default_data,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg valid_out,
    output reg load_out,
    output reg [DATA_WIDTH-1:0] preset_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= default_data;
            valid_out <= 1'b0;
            load_out <= 1'b0;
            preset_out <= {DATA_WIDTH{1'b0}};
        end else if (enable) begin
            data_out <= data_in;
            valid_out <= valid_in;
            load_out <= load_in;
            preset_out <= preset_in;
        end else begin
            valid_out <= 1'b0;
        end
    end

endmodule

// 简化版的输出阶段模块
module output_stage #(
    parameter DATA_WIDTH = 4
)(
    input wire clk,
    input wire rst_n,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire valid_in,
    input wire enable,
    input wire [DATA_WIDTH-1:0] default_data,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg valid_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= default_data;
            valid_out <= 1'b0;
        end else if (enable) begin
            data_out <= data_in;
            valid_out <= valid_in;
        end else begin
            valid_out <= 1'b0;
        end
    end

endmodule