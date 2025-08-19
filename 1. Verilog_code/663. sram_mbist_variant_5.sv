//SystemVerilog
// Top level module
module sram_mbist #(
    parameter AW = 5,
    parameter DW = 8
)(
    input clk,
    input test_mode,
    output error_flag
);

    // Internal signals
    wire [AW:0] test_counter;
    wire [AW:0] test_counter_buf;
    wire test_stage;
    wire [DW-1:0] expected;
    wire [DW-1:0] mem_data;
    wire [AW-1:0] mem_addr;

    // Counter module instance
    counter #(
        .WIDTH(AW+1)
    ) counter_inst (
        .clk(clk),
        .test_mode(test_mode),
        .count(test_counter)
    );

    // Buffer module instance
    buffer #(
        .WIDTH(AW+1)
    ) buffer_inst (
        .clk(clk),
        .test_mode(test_mode),
        .din(test_counter),
        .dout(test_counter_buf)
    );

    // Stage control module instance
    stage_ctrl stage_ctrl_inst (
        .clk(clk),
        .test_mode(test_mode),
        .counter_msb(test_counter_buf[AW]),
        .stage(test_stage)
    );

    // Expected data generator
    expected_gen #(
        .DW(DW)
    ) expected_gen_inst (
        .test_stage(test_stage),
        .expected(expected)
    );

    // Memory module instance
    sram #(
        .AW(AW),
        .DW(DW)
    ) sram_inst (
        .clk(clk),
        .test_mode(test_mode),
        .addr(mem_addr),
        .data_in(expected),
        .data_out(mem_data)
    );

    // Error detection module
    error_detector #(
        .DW(DW)
    ) error_detector_inst (
        .test_mode(test_mode),
        .mem_data(mem_data),
        .expected(expected),
        .error_flag(error_flag)
    );

    assign mem_addr = test_counter_buf[AW-1:0];

endmodule

// Counter module
module counter #(
    parameter WIDTH = 6
)(
    input clk,
    input test_mode,
    output reg [WIDTH-1:0] count
);

    always @(posedge clk) begin
        if (test_mode)
            count <= count + 1;
    end

endmodule

// Buffer module
module buffer #(
    parameter WIDTH = 6
)(
    input clk,
    input test_mode,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);

    always @(posedge clk) begin
        if (test_mode)
            dout <= din;
    end

endmodule

// Stage control module
module stage_ctrl(
    input clk,
    input test_mode,
    input counter_msb,
    output reg stage
);

    always @(posedge clk) begin
        if (test_mode && counter_msb)
            stage <= ~stage;
    end

endmodule

// Expected data generator
module expected_gen #(
    parameter DW = 8
)(
    input test_stage,
    output [DW-1:0] expected
);

    assign expected = test_stage ? {DW{1'b1}} : {DW{1'b0}};

endmodule

// SRAM module
module sram #(
    parameter AW = 5,
    parameter DW = 8
)(
    input clk,
    input test_mode,
    input [AW-1:0] addr,
    input [DW-1:0] data_in,
    output [DW-1:0] data_out
);

    reg [DW-1:0] mem [0:(1<<AW)-1];

    always @(posedge clk) begin
        if (test_mode)
            mem[addr] <= data_in;
    end

    assign data_out = mem[addr];

endmodule

// Error detector module
module error_detector #(
    parameter DW = 8
)(
    input test_mode,
    input [DW-1:0] mem_data,
    input [DW-1:0] expected,
    output error_flag
);

    assign error_flag = test_mode ? (mem_data !== expected) : 1'b0;

endmodule