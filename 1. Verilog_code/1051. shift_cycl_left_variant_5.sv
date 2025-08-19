//SystemVerilog
module shift_cycl_left #(
    parameter WIDTH = 8
)(
    input                  clk,
    input                  rst_n,
    input                  en,
    input  [WIDTH-1:0]     data_in,
    output [WIDTH-1:0]     data_out,
    output                 data_out_valid
);

    // Stage 1: Input register and valid
    reg [WIDTH-1:0] data_in_stage1;
    reg             valid_stage1;

    // Stage 2: Shift operation and valid
    reg [WIDTH-1:0] data_shifted_stage2;
    reg             valid_stage2;

    // Output assign
    assign data_out       = data_shifted_stage2;
    assign data_out_valid = valid_stage2;

    // Stage 1: Capture input
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage1 <= {WIDTH{1'b0}};
            valid_stage1   <= 1'b0;
        end else if (en) begin
            data_in_stage1 <= data_in;
            valid_stage1   <= 1'b1;
        end else begin
            valid_stage1   <= 1'b0;
        end
    end

    // Stage 2: Perform cyclic left shift
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_shifted_stage2 <= {WIDTH{1'b0}};
            valid_stage2        <= 1'b0;
        end else if (valid_stage1) begin
            data_shifted_stage2 <= {data_in_stage1[WIDTH-2:0], data_in_stage1[WIDTH-1]};
            valid_stage2        <= 1'b1;
        end else begin
            valid_stage2        <= 1'b0;
        end
    end

endmodule