//SystemVerilog
module shift_parallel_load_pipeline #(
    parameter DEPTH = 4
)(
    input              clk,
    input              rst_n,
    input              load,
    input      [7:0]   pdata,
    output reg [7:0]   sout,
    output reg         sout_valid
);

// Stage 1: Shift Register Logic
reg [7:0] shift_reg_stage1;
always @(posedge clk or negedge rst_n) begin : shift_register_stage1_logic
    if (!rst_n)
        shift_reg_stage1 <= 8'b0;
    else if (load)
        shift_reg_stage1 <= pdata;
    else
        shift_reg_stage1 <= {shift_reg_stage1[6:0], 1'b0};
end

// Stage 1: Valid Flag Logic
reg valid_stage1;
always @(posedge clk or negedge rst_n) begin : valid_stage1_logic
    if (!rst_n)
        valid_stage1 <= 1'b0;
    else
        valid_stage1 <= 1'b1;
end

// Stage 2: Output Data Register Logic
reg [7:0] sout_stage2;
always @(posedge clk or negedge rst_n) begin : sout_stage2_logic
    if (!rst_n)
        sout_stage2 <= 8'b0;
    else
        sout_stage2 <= shift_reg_stage1;
end

// Stage 2: Output Valid Flag Logic
reg valid_stage2;
always @(posedge clk or negedge rst_n) begin : valid_stage2_logic
    if (!rst_n)
        valid_stage2 <= 1'b0;
    else
        valid_stage2 <= valid_stage1;
end

// Stage 3: Final Output Data Register Logic
always @(posedge clk or negedge rst_n) begin : sout_logic
    if (!rst_n)
        sout <= 8'b0;
    else
        sout <= sout_stage2;
end

// Stage 3: Final Output Valid Flag Logic
always @(posedge clk or negedge rst_n) begin : sout_valid_logic
    if (!rst_n)
        sout_valid <= 1'b0;
    else
        sout_valid <= valid_stage2;
end

endmodule