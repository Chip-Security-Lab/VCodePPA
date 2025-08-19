//SystemVerilog
module BiDirShift #(parameter BITS=8) (
    input clk, rst, dir, s_in,
    output reg [BITS-1:0] q
);

// Pipeline stage 1 registers
reg [BITS-1:0] q_stage1;
reg dir_stage1;
reg s_in_stage1;

// Pipeline stage 2 registers
reg [BITS-1:0] q_stage2;
reg dir_stage2;
reg s_in_stage2;

// Pipeline stage 3 registers
reg [BITS-1:0] q_stage3;
reg dir_stage3;
reg s_in_stage3;

// Pipeline control signals
reg valid_stage1, valid_stage2, valid_stage3;

// Stage 1: Input capture and initial shift
always @(posedge clk) begin
    if (rst) begin
        q_stage1 <= 0;
        dir_stage1 <= 0;
        s_in_stage1 <= 0;
        valid_stage1 <= 0;
    end else begin
        q_stage1 <= q;
        dir_stage1 <= dir;
        s_in_stage1 <= s_in;
        valid_stage1 <= 1;
    end
end

// Stage 2: First shift operation
always @(posedge clk) begin
    if (rst) begin
        q_stage2 <= 0;
        dir_stage2 <= 0;
        s_in_stage2 <= 0;
        valid_stage2 <= 0;
    end else if (valid_stage1) begin
        q_stage2 <= dir_stage1 ? {q_stage1[BITS-2:0], s_in_stage1} : {s_in_stage1, q_stage1[BITS-1:1]};
        dir_stage2 <= dir_stage1;
        s_in_stage2 <= s_in_stage1;
        valid_stage2 <= 1;
    end else begin
        valid_stage2 <= 0;
    end
end

// Stage 3: Second shift operation
always @(posedge clk) begin
    if (rst) begin
        q_stage3 <= 0;
        dir_stage3 <= 0;
        s_in_stage3 <= 0;
        valid_stage3 <= 0;
    end else if (valid_stage2) begin
        q_stage3 <= dir_stage2 ? {q_stage2[BITS-2:0], s_in_stage2} : {s_in_stage2, q_stage2[BITS-1:1]};
        dir_stage3 <= dir_stage2;
        s_in_stage3 <= s_in_stage2;
        valid_stage3 <= 1;
    end else begin
        valid_stage3 <= 0;
    end
end

// Final output stage
always @(posedge clk) begin
    if (rst) begin
        q <= 0;
    end else if (valid_stage3) begin
        q <= dir_stage3 ? {q_stage3[BITS-2:0], s_in_stage3} : {s_in_stage3, q_stage3[BITS-1:1]};
    end
end

endmodule