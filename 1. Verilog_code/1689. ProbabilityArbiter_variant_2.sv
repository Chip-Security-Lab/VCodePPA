//SystemVerilog
module ProbabilityArbiter #(parameter SEED=8'hA5) (
    input clk, rst,
    input [3:0] req,
    output reg [3:0] grant
);

// Stage 1 signals
reg [7:0] lfsr_stage1;
reg [3:0] req_mask_stage1;
reg valid_stage1;

// Stage 2 signals
reg [1:0] lfsr_low_stage2;
reg [3:0] req_mask_stage2;
reg valid_stage2;

// Stage 3 signals
reg [3:0] grant_stage3;
reg valid_stage3;

// Stage 1: LFSR generation with optimized polynomial
always @(posedge clk) begin
    if(rst) begin
        lfsr_stage1 <= SEED;
    end else begin
        lfsr_stage1 <= {lfsr_stage1[6:0], ^(lfsr_stage1[7:3] & 5'b11001)};
    end
end

// Stage 1: Request masking with optimized logic
always @(posedge clk) begin
    if(rst) begin
        req_mask_stage1 <= 0;
    end else begin
        req_mask_stage1 <= req & {4{|req}};
    end
end

// Stage 1: Valid signal generation
always @(posedge clk) begin
    if(rst) begin
        valid_stage1 <= 0;
    end else begin
        valid_stage1 <= 1;
    end
end

// Stage 2: LFSR low bits pipeline
always @(posedge clk) begin
    if(rst) begin
        lfsr_low_stage2 <= 0;
    end else begin
        lfsr_low_stage2 <= lfsr_stage1[1:0];
    end
end

// Stage 2: Request mask pipeline
always @(posedge clk) begin
    if(rst) begin
        req_mask_stage2 <= 0;
    end else begin
        req_mask_stage2 <= req_mask_stage1;
    end
end

// Stage 2: Valid signal pipeline
always @(posedge clk) begin
    if(rst) begin
        valid_stage2 <= 0;
    end else begin
        valid_stage2 <= valid_stage1;
    end
end

// Stage 3: Grant selection logic with optimized case statement
always @(posedge clk) begin
    if(rst) begin
        grant_stage3 <= 0;
    end else if(valid_stage2) begin
        grant_stage3 <= req_mask_stage2 & (4'b0001 << lfsr_low_stage2);
    end else begin
        grant_stage3 <= 0;
    end
end

// Stage 3: Valid signal pipeline
always @(posedge clk) begin
    if(rst) begin
        valid_stage3 <= 0;
    end else begin
        valid_stage3 <= valid_stage2;
    end
end

// Output assignment
assign grant = grant_stage3;

endmodule