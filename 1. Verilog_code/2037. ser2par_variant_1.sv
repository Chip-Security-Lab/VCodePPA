//SystemVerilog
module ser2par #(
    parameter WIDTH = 8
)(
    input  clk,
    input  rst_n,
    input  en,
    input  ser_in,
    output reg [WIDTH-1:0] par_out,
    output reg par_valid
);

    // Stage 1: Shift register input and serial-to-parallel operation
    reg [WIDTH-1:0] shift_reg_stage1;
    reg             match_stage1;
    reg             valid_stage1;

    // Stage 2: Output register and valid signal
    reg [WIDTH-1:0] par_out_stage2;
    reg             valid_stage2;

    // Stage 1: Shift in serial data and check for all 1's
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_stage1 <= {WIDTH{1'b0}};
            match_stage1     <= 1'b0;
            valid_stage1     <= 1'b0;
        end else if (en) begin
            shift_reg_stage1 <= {shift_reg_stage1[WIDTH-2:0], ser_in};
            match_stage1     <= ({shift_reg_stage1[WIDTH-2:0], ser_in} == {WIDTH{1'b1}});
            valid_stage1     <= 1'b1;
        end else begin
            valid_stage1     <= 1'b0;
            match_stage1     <= 1'b0;
        end
    end

    // Stage 2: Latch output when all 1's detected, propagate valid
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            par_out_stage2 <= {WIDTH{1'b0}};
            valid_stage2   <= 1'b0;
        end else if (valid_stage1 && match_stage1) begin
            par_out_stage2 <= shift_reg_stage1;
            valid_stage2   <= 1'b1;
        end else begin
            valid_stage2   <= 1'b0;
        end
    end

    // Output assignments
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            par_out   <= {WIDTH{1'b0}};
            par_valid <= 1'b0;
        end else begin
            par_out   <= par_out_stage2;
            par_valid <= valid_stage2;
        end
    end

endmodule