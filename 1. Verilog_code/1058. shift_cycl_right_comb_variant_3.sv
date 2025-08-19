//SystemVerilog
// Top-level module: shift_cycl_right_pipeline
// Function: Performs pipelined cyclic right shift on input vector 'din'

module shift_cycl_right_pipeline #(parameter WIDTH=8) (
    input                  clk,
    input                  rst_n,
    input  [WIDTH-1:0]     din,
    input  [2:0]           shift_amt,
    output [WIDTH-1:0]     dout
);

    // Stage 1: Input Register
    reg [WIDTH-1:0]        din_reg_stage1;
    reg [2:0]              shift_amt_reg_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            din_reg_stage1       <= {WIDTH{1'b0}};
            shift_amt_reg_stage1 <= 3'b0;
        end else begin
            din_reg_stage1       <= din;
            shift_amt_reg_stage1 <= shift_amt;
        end
    end

    // Stage 2: Calculate inverse shift amount (WIDTH - shift_amt) modulo WIDTH
    reg [2:0]              inv_shift_amt_reg_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            inv_shift_amt_reg_stage2 <= 3'b0;
        end else if (shift_amt_reg_stage1 == 0) begin
            inv_shift_amt_reg_stage2 <= 3'b0;
        end else begin
            inv_shift_amt_reg_stage2 <= WIDTH[2:0] - shift_amt_reg_stage1;
        end
    end

    // Stage 2: Register data for shift units
    reg [WIDTH-1:0]        din_reg_stage2;
    reg [2:0]              shift_amt_reg_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            din_reg_stage2        <= {WIDTH{1'b0}};
            shift_amt_reg_stage2  <= 3'b0;
        end else begin
            din_reg_stage2        <= din_reg_stage1;
            shift_amt_reg_stage2  <= shift_amt_reg_stage1;
        end
    end

    // Stage 3: Perform right and left shifts in parallel
    reg [WIDTH-1:0]        right_shifted_reg_stage3;
    reg [WIDTH-1:0]        left_shifted_reg_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            right_shifted_reg_stage3 <= {WIDTH{1'b0}};
            left_shifted_reg_stage3  <= {WIDTH{1'b0}};
        end else if ((shift_amt_reg_stage2 == 0) && (inv_shift_amt_reg_stage2 == 0)) begin
            right_shifted_reg_stage3 <= din_reg_stage2;
            left_shifted_reg_stage3  <= {WIDTH{1'b0}};
        end else if ((shift_amt_reg_stage2 != 0) && (inv_shift_amt_reg_stage2 == 0)) begin
            right_shifted_reg_stage3 <= din_reg_stage2 >> shift_amt_reg_stage2;
            left_shifted_reg_stage3  <= {WIDTH{1'b0}};
        end else if ((shift_amt_reg_stage2 == 0) && (inv_shift_amt_reg_stage2 != 0)) begin
            right_shifted_reg_stage3 <= din_reg_stage2;
            left_shifted_reg_stage3  <= din_reg_stage2 << inv_shift_amt_reg_stage2;
        end else begin
            right_shifted_reg_stage3 <= din_reg_stage2 >> shift_amt_reg_stage2;
            left_shifted_reg_stage3  <= din_reg_stage2 << inv_shift_amt_reg_stage2;
        end
    end

    // Stage 4: Output Register (Bitwise OR)
    reg [WIDTH-1:0]        dout_reg_stage4;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_reg_stage4 <= {WIDTH{1'b0}};
        end else if ((shift_amt_reg_stage2 == 0) && (inv_shift_amt_reg_stage2 == 0)) begin
            dout_reg_stage4 <= right_shifted_reg_stage3;
        end else if ((shift_amt_reg_stage2 != 0) && (inv_shift_amt_reg_stage2 == 0)) begin
            dout_reg_stage4 <= right_shifted_reg_stage3;
        end else if ((shift_amt_reg_stage2 == 0) && (inv_shift_amt_reg_stage2 != 0)) begin
            dout_reg_stage4 <= right_shifted_reg_stage3 | left_shifted_reg_stage3;
        end else begin
            dout_reg_stage4 <= right_shifted_reg_stage3 | left_shifted_reg_stage3;
        end
    end

    assign dout = dout_reg_stage4;

endmodule