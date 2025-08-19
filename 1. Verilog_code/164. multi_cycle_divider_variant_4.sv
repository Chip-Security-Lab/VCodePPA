//SystemVerilog
// Parameterized pipeline stage module
module pipeline_stage #(
    parameter DATA_WIDTH = 8,
    parameter COUNT_WIDTH = 4
)(
    input clk,
    input reset,
    input [DATA_WIDTH-1:0] data_in,
    input [DATA_WIDTH-1:0] divisor_in,
    input [COUNT_WIDTH-1:0] count_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg [DATA_WIDTH-1:0] divisor_out,
    output reg [COUNT_WIDTH-1:0] count_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_out <= 0;
            divisor_out <= 0;
            count_out <= 0;
        end else begin
            data_out <= data_in;
            divisor_out <= divisor_in;
            count_out <= count_in;
        end
    end
endmodule

// Input stage module with counter logic
module input_stage #(
    parameter DATA_WIDTH = 8,
    parameter COUNT_WIDTH = 4
)(
    input clk,
    input reset,
    input [DATA_WIDTH-1:0] a,
    input [DATA_WIDTH-1:0] b,
    output reg [DATA_WIDTH-1:0] a_out,
    output reg [DATA_WIDTH-1:0] b_out,
    output reg [COUNT_WIDTH-1:0] count_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            a_out <= 0;
            b_out <= 0;
            count_out <= 0;
        end else begin
            a_out <= a;
            b_out <= b;
            count_out <= (count_out < 8) ? count_out + 1 : 0;
        end
    end
endmodule

// Output stage module with division logic
module output_stage #(
    parameter DATA_WIDTH = 8,
    parameter COUNT_WIDTH = 4
)(
    input clk,
    input reset,
    input [DATA_WIDTH-1:0] dividend_in,
    input [DATA_WIDTH-1:0] divisor_in,
    input [COUNT_WIDTH-1:0] count_in,
    output reg [DATA_WIDTH-1:0] quotient,
    output reg [DATA_WIDTH-1:0] remainder
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            quotient <= 0;
            remainder <= 0;
        end else begin
            if (count_in < 8) begin
                quotient <= dividend_in / divisor_in;
                remainder <= dividend_in % divisor_in;
            end
        end
    end
endmodule

// Top-level multi-cycle divider module
module multi_cycle_divider (
    input clk,
    input reset,
    input [7:0] a,
    input [7:0] b,
    output [7:0] quotient,
    output [7:0] remainder
);
    // Internal signals
    wire [7:0] a_stage1, b_stage1;
    wire [3:0] count_stage1;
    
    wire [7:0] dividend_stage2, divisor_stage2;
    wire [3:0] count_stage2;
    
    wire [7:0] dividend_stage3, divisor_stage3;
    wire [3:0] count_stage3;
    
    wire [7:0] dividend_stage4, divisor_stage4;
    wire [3:0] count_stage4;
    
    wire [7:0] dividend_stage5, divisor_stage5;
    wire [3:0] count_stage5;
    
    // Instantiate input stage
    input_stage #(
        .DATA_WIDTH(8),
        .COUNT_WIDTH(4)
    ) input_stage_inst (
        .clk(clk),
        .reset(reset),
        .a(a),
        .b(b),
        .a_out(a_stage1),
        .b_out(b_stage1),
        .count_out(count_stage1)
    );
    
    // Instantiate pipeline stages
    pipeline_stage #(
        .DATA_WIDTH(8),
        .COUNT_WIDTH(4)
    ) stage2 (
        .clk(clk),
        .reset(reset),
        .data_in(a_stage1),
        .divisor_in(b_stage1),
        .count_in(count_stage1),
        .data_out(dividend_stage2),
        .divisor_out(divisor_stage2),
        .count_out(count_stage2)
    );
    
    pipeline_stage #(
        .DATA_WIDTH(8),
        .COUNT_WIDTH(4)
    ) stage3 (
        .clk(clk),
        .reset(reset),
        .data_in(dividend_stage2),
        .divisor_in(divisor_stage2),
        .count_in(count_stage2),
        .data_out(dividend_stage3),
        .divisor_out(divisor_stage3),
        .count_out(count_stage3)
    );
    
    pipeline_stage #(
        .DATA_WIDTH(8),
        .COUNT_WIDTH(4)
    ) stage4 (
        .clk(clk),
        .reset(reset),
        .data_in(dividend_stage3),
        .divisor_in(divisor_stage3),
        .count_in(count_stage3),
        .data_out(dividend_stage4),
        .divisor_out(divisor_stage4),
        .count_out(count_stage4)
    );
    
    pipeline_stage #(
        .DATA_WIDTH(8),
        .COUNT_WIDTH(4)
    ) stage5 (
        .clk(clk),
        .reset(reset),
        .data_in(dividend_stage4),
        .divisor_in(divisor_stage4),
        .count_in(count_stage4),
        .data_out(dividend_stage5),
        .divisor_out(divisor_stage5),
        .count_out(count_stage5)
    );
    
    // Instantiate output stage
    output_stage #(
        .DATA_WIDTH(8),
        .COUNT_WIDTH(4)
    ) output_stage_inst (
        .clk(clk),
        .reset(reset),
        .dividend_in(dividend_stage5),
        .divisor_in(divisor_stage5),
        .count_in(count_stage5),
        .quotient(quotient),
        .remainder(remainder)
    );
endmodule