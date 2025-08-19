//SystemVerilog
module bidirectional_shifter #(parameter DATA_W=16) (
    input  wire                          clk,
    input  wire                          rst_n,
    input  wire [DATA_W-1:0]             data_in,
    input  wire [$clog2(DATA_W)-1:0]     shift_amount,
    input  wire                          shift_left,        // Direction control: 1=left, 0=right
    input  wire                          shift_arithmetic,  // 1=arithmetic, 0=logical
    input  wire                          valid_in,
    output wire [DATA_W-1:0]             shift_result,
    output wire                          valid_out
);

    // Stage 1: Input Register
    reg [DATA_W-1:0]               data_stage1;
    reg [$clog2(DATA_W)-1:0]       amount_stage1;
    reg                            left_stage1;
    reg                            arithmetic_stage1;
    reg                            valid_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1        <= {DATA_W{1'b0}};
            amount_stage1      <= {($clog2(DATA_W)){1'b0}};
            left_stage1        <= 1'b0;
            arithmetic_stage1  <= 1'b0;
            valid_stage1       <= 1'b0;
        end else begin
            data_stage1        <= data_in;
            amount_stage1      <= shift_amount;
            left_stage1        <= shift_left;
            arithmetic_stage1  <= shift_arithmetic;
            valid_stage1       <= valid_in;
        end
    end

    // Stage 2: Shift Operation
    reg [DATA_W-1:0]         shifted_stage2;
    reg                      valid_stage2;
    reg                      arithmetic_stage2;
    reg                      left_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shifted_stage2      <= {DATA_W{1'b0}};
            valid_stage2        <= 1'b0;
            arithmetic_stage2   <= 1'b0;
            left_stage2         <= 1'b0;
        end else begin
            if (left_stage1) begin
                shifted_stage2 <= data_stage1 << amount_stage1;
            end else if (arithmetic_stage1) begin
                shifted_stage2 <= $signed(data_stage1) >>> amount_stage1;
            end else begin
                shifted_stage2 <= data_stage1 >> amount_stage1;
            end
            valid_stage2      <= valid_stage1;
            arithmetic_stage2 <= arithmetic_stage1;
            left_stage2       <= left_stage1;
        end
    end

    // Stage 3: Output Register
    reg [DATA_W-1:0]   result_stage3;
    reg                valid_stage3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_stage3 <= {DATA_W{1'b0}};
            valid_stage3  <= 1'b0;
        end else begin
            result_stage3 <= shifted_stage2;
            valid_stage3  <= valid_stage2;
        end
    end

    assign shift_result = result_stage3;
    assign valid_out    = valid_stage3;

endmodule