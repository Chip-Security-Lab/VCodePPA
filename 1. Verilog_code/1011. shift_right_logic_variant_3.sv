//SystemVerilog
// Top-level pipelined right shifter with hierarchical structure
module shift_right_pipeline #(
    parameter WIDTH = 8
)(
    input                   clk,
    input                   rst_n,
    input  [WIDTH-1:0]      data_in,
    input  [2:0]            shift_amount,
    output [WIDTH-1:0]      data_out
);

    // Stage 1: Input Registering
    wire [WIDTH-1:0] stage1_data;
    wire [2:0]       stage1_shift;
    shift_right_pipeline_stage1 #(
        .WIDTH(WIDTH)
    ) u_stage1 (
        .clk         (clk),
        .rst_n       (rst_n),
        .data_in     (data_in),
        .shift_in    (shift_amount),
        .data_out    (stage1_data),
        .shift_out   (stage1_shift)
    );

    // Stage 2: First Part of Shift (shift by lower 2 bits)
    wire [WIDTH-1:0] stage2_data;
    wire [2:0]       stage2_shift;
    shift_right_pipeline_stage2 #(
        .WIDTH(WIDTH)
    ) u_stage2 (
        .clk         (clk),
        .rst_n       (rst_n),
        .data_in     (stage1_data),
        .shift_in    (stage1_shift),
        .data_out    (stage2_data),
        .shift_out   (stage2_shift)
    );

    // Stage 3: Second Part of Shift (shift by upper bit)
    wire [WIDTH-1:0] stage3_data;
    wire [2:0]       stage3_shift;
    shift_right_pipeline_stage3 #(
        .WIDTH(WIDTH)
    ) u_stage3 (
        .clk         (clk),
        .rst_n       (rst_n),
        .data_in     (stage2_data),
        .shift_in    (stage2_shift),
        .data_out    (stage3_data),
        .shift_out   (stage3_shift)
    );

    // Stage 4: Output Registering
    shift_right_pipeline_stage4 #(
        .WIDTH(WIDTH)
    ) u_stage4 (
        .clk         (clk),
        .rst_n       (rst_n),
        .data_in     (stage3_data),
        .data_out    (data_out)
    );

endmodule

//-----------------------------------------------------------------------------
// Stage 1: Input Registering
// Registers the input data and shift value
module shift_right_pipeline_stage1 #(
    parameter WIDTH = 8
)(
    input                   clk,
    input                   rst_n,
    input  [WIDTH-1:0]      data_in,
    input  [2:0]            shift_in,
    output reg [WIDTH-1:0]  data_out,
    output reg [2:0]        shift_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out  <= {WIDTH{1'b0}};
            shift_out <= 3'b0;
        end else begin
            data_out  <= data_in;
            shift_out <= shift_in;
        end
    end
endmodule

//-----------------------------------------------------------------------------
// Stage 2: First Part of Shift (by lower 2 bits of shift amount)
// Performs right shift by 0-3 bits according to shift_in[1:0]
module shift_right_pipeline_stage2 #(
    parameter WIDTH = 8
)(
    input                   clk,
    input                   rst_n,
    input  [WIDTH-1:0]      data_in,
    input  [2:0]            shift_in,
    output reg [WIDTH-1:0]  data_out,
    output reg [2:0]        shift_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out  <= {WIDTH{1'b0}};
            shift_out <= 3'b0;
        end else begin
            case (shift_in[1:0])
                2'b00: data_out <= data_in;
                2'b01: data_out <= data_in >> 1;
                2'b10: data_out <= data_in >> 2;
                2'b11: data_out <= data_in >> 3;
                default: data_out <= data_in;
            endcase
            shift_out <= shift_in;
        end
    end
endmodule

//-----------------------------------------------------------------------------
// Stage 3: Second Part of Shift (by upper bit of shift amount)
// Performs additional right shift by 4 if shift_in[2] is set
module shift_right_pipeline_stage3 #(
    parameter WIDTH = 8
)(
    input                   clk,
    input                   rst_n,
    input  [WIDTH-1:0]      data_in,
    input  [2:0]            shift_in,
    output reg [WIDTH-1:0]  data_out,
    output reg [2:0]        shift_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out  <= {WIDTH{1'b0}};
            shift_out <= 3'b0;
        end else begin
            if (shift_in[2])
                data_out <= data_in >> 4;
            else
                data_out <= data_in;
            shift_out <= shift_in;
        end
    end
endmodule

//-----------------------------------------------------------------------------
// Stage 4: Output Registering
// Registers the final shifted data
module shift_right_pipeline_stage4 #(
    parameter WIDTH = 8
)(
    input                   clk,
    input                   rst_n,
    input  [WIDTH-1:0]      data_in,
    output reg [WIDTH-1:0]  data_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {WIDTH{1'b0}};
        end else begin
            data_out <= data_in;
        end
    end
endmodule