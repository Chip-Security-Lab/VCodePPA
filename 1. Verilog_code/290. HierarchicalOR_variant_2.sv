//SystemVerilog

// Generic parameterized OR module
module GenericOR #(parameter WIDTH = 1)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] y
);

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : bit_or_gen
            assign y[i] = a[i] | b[i];
        end
    endgenerate

endmodule

// Pipelined Hierarchical OR module using generic OR
module HierarchicalOR_Pipelined_Refactored #(parameter DATA_WIDTH = 2)(
    input clk,
    input reset,
    input [DATA_WIDTH-1:0] a, b,
    output [DATA_WIDTH+1:0] y // Output width is DATA_WIDTH + 2 based on original logic
);

    reg [DATA_WIDTH-1:0] a_reg;
    reg [DATA_WIDTH-1:0] b_reg;
    wire [DATA_WIDTH-1:0] or_stage1_out;
    reg [DATA_WIDTH-1:0] or_stage1_reg;
    reg [DATA_WIDTH+1:0] final_output_reg;

    // Input buffering stage
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            a_reg <= {DATA_WIDTH{1'b0}};
            b_reg <= {DATA_WIDTH{1'b0}};
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end

    // Stage 1: Bitwise OR
    GenericOR #(DATA_WIDTH) stage1_inst (
        .a(a_reg),
        .b(b_reg),
        .y(or_stage1_out)
    );

    // Stage 2: Registering Stage 1 output
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            or_stage1_reg <= {DATA_WIDTH{1'b0}};
        end else begin
            or_stage1_reg <= or_stage1_out;
        end
    end

    // Final output stage (based on original logic {2'b11, or_stage1_reg})
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            final_output_reg <= {DATA_WIDTH+2{1'b0}};
        end else begin
            // Assuming the original logic of prepending 2'b11
            final_output_reg <= {2'b11, or_stage1_reg};
        end
    end

    assign y = final_output_reg;

endmodule