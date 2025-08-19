//SystemVerilog
module shift_right_arithmetic_pipeline #(parameter WIDTH=8) (
    input clk,
    input rst_n,
    input en,
    input signed [WIDTH-1:0] data_in,
    input [2:0] shift,
    output reg signed [WIDTH-1:0] data_out,
    output reg valid_out
);

// Stage 1: Input Registering
reg signed [WIDTH-1:0] data_in_stage1;
reg [2:0] shift_stage1;
reg valid_stage1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_in_stage1 <= {WIDTH{1'b0}};
        shift_stage1 <= 3'b0;
        valid_stage1 <= 1'b0;
    end else if (en) begin
        data_in_stage1 <= data_in;
        shift_stage1 <= shift;
        valid_stage1 <= 1'b1;
    end else begin
        valid_stage1 <= 1'b0;
    end
end

// Stage 2: Arithmetic Shift
reg signed [WIDTH-1:0] shifted_data_stage2;
reg valid_stage2;

wire signed [WIDTH-1:0] shift_result;

// 3-bit borrow subtractor instance: data_in_stage1 - (1 << shift_stage1)
wire [2:0] subtractor_a;
wire [2:0] subtractor_b;
wire [2:0] subtractor_diff;
wire subtractor_borrow_out;

assign subtractor_a = data_in_stage1[2:0];
assign subtractor_b = (3'b1 << shift_stage1);

borrow_subtractor_3bit u_borrow_subtractor_3bit (
    .minuend(subtractor_a),
    .subtrahend(subtractor_b),
    .difference(subtractor_diff),
    .borrow_out(subtractor_borrow_out)
);

assign shift_result = { { (WIDTH-3){data_in_stage1[WIDTH-1]} }, subtractor_diff };

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        shifted_data_stage2 <= {WIDTH{1'b0}};
        valid_stage2 <= 1'b0;
    end else begin
        shifted_data_stage2 <= shift_result;
        valid_stage2 <= valid_stage1;
    end
end

// Stage 3: Output Register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_out <= {WIDTH{1'b0}};
        valid_out <= 1'b0;
    end else begin
        data_out <= shifted_data_stage2;
        valid_out <= valid_stage2;
    end
end

endmodule

// 3-bit Borrow Subtractor (Minuend - Subtrahend = Difference), with borrow out
module borrow_subtractor_3bit (
    input  [2:0] minuend,
    input  [2:0] subtrahend,
    output [2:0] difference,
    output       borrow_out
);
    wire [2:0] borrow;

    // Bit 0
    assign difference[0] = minuend[0] ^ subtrahend[0];
    assign borrow[0]     = (~minuend[0] & subtrahend[0]);

    // Bit 1
    assign difference[1] = minuend[1] ^ subtrahend[1] ^ borrow[0];
    assign borrow[1]     = (~minuend[1] & subtrahend[1]) | ((~minuend[1] | subtrahend[1]) & borrow[0]);

    // Bit 2
    assign difference[2] = minuend[2] ^ subtrahend[2] ^ borrow[1];
    assign borrow[2]     = (~minuend[2] & subtrahend[2]) | ((~minuend[2] | subtrahend[2]) & borrow[1]);

    assign borrow_out    = borrow[2];
endmodule