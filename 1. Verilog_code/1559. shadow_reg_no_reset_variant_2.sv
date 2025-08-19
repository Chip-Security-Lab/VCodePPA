//SystemVerilog
module shadow_reg_no_reset #(parameter WIDTH=4) (
    input clk, enable,
    input [WIDTH-1:0] input_data,
    output [WIDTH-1:0] output_data
);

    // Instantiate pipeline stages
    wire [WIDTH-1:0] stage1_output;
    wire [WIDTH-1:0] stage2_output;

    // Stage 1: Input Capture
    input_capture_stage #(WIDTH) stage1 (
        .clk(clk),
        .enable(enable),
        .input_data(input_data),
        .output_data(stage1_output)
    );

    // Stage 2: Intermediate Stage
    intermediate_stage #(WIDTH) stage2 (
        .clk(clk),
        .enable(stage1_output),
        .input_data(stage1_output),
        .output_data(stage2_output)
    );

    // Stage 3: Pre-output Stage
    output_stage #(WIDTH) stage3 (
        .clk(clk),
        .enable(stage2_output),
        .input_data(stage2_output),
        .output_data(output_data)
    );

endmodule

// Stage 1: Input Capture Module
module input_capture_stage #(parameter WIDTH=4) (
    input clk, enable,
    input [WIDTH-1:0] input_data,
    output reg [WIDTH-1:0] output_data
);
    always @(posedge clk) begin
        output_data <= enable ? input_data : output_data;
    end
endmodule

// Stage 2: Intermediate Stage Module
module intermediate_stage #(parameter WIDTH=4) (
    input clk, enable,
    input [WIDTH-1:0] input_data,
    output reg [WIDTH-1:0] output_data
);
    always @(posedge clk) begin
        output_data <= enable ? input_data : output_data;
    end
endmodule

// Stage 3: Output Stage Module
module output_stage #(parameter WIDTH=4) (
    input clk, enable,
    input [WIDTH-1:0] input_data,
    output reg [WIDTH-1:0] output_data
);
    always @(posedge clk) begin
        output_data <= input_data;
    end
endmodule