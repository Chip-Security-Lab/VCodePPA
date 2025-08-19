//SystemVerilog
module ProbabilityArbiter #(parameter SEED=8'hA5) (
    input clk, rst,
    input [3:0] req,
    output reg [3:0] grant
);

// Stage 1: LFSR and Request Processing
reg [7:0] lfsr_stage1 = SEED;
reg [3:0] req_mask_stage1;
reg valid_stage1;

// Stage 2: Grant Generation
reg [7:0] lfsr_stage2;
reg [3:0] req_mask_stage2;
reg valid_stage2;

// Stage 3: Grant Output
reg [7:0] lfsr_stage3;
reg [3:0] req_mask_stage3;
reg valid_stage3;

// Optimized LFSR polynomial: x^8 + x^5 + x^4 + x^3 + 1
wire lfsr_feedback = lfsr_stage1[7] ^ lfsr_stage1[4] ^ lfsr_stage1[3] ^ lfsr_stage1[2];

// Stage 1 Logic
always @(posedge clk) begin
    if(rst) begin
        lfsr_stage1 <= SEED;
        req_mask_stage1 <= 0;
        valid_stage1 <= 0;
    end else begin
        lfsr_stage1 <= {lfsr_stage1[6:0], lfsr_feedback};
        req_mask_stage1 <= req & {4{|req}};
        valid_stage1 <= 1;
    end
end

// Stage 2 Logic
always @(posedge clk) begin
    if(rst) begin
        lfsr_stage2 <= SEED;
        req_mask_stage2 <= 0;
        valid_stage2 <= 0;
    end else begin
        lfsr_stage2 <= lfsr_stage1;
        req_mask_stage2 <= req_mask_stage1;
        valid_stage2 <= valid_stage1;
    end
end

// Stage 3 Logic
always @(posedge clk) begin
    if(rst) begin
        lfsr_stage3 <= SEED;
        req_mask_stage3 <= 0;
        valid_stage3 <= 0;
        grant <= 0;
    end else begin
        lfsr_stage3 <= lfsr_stage2;
        req_mask_stage3 <= req_mask_stage2;
        valid_stage3 <= valid_stage2;
        
        if(valid_stage3) begin
            grant <= req_mask_stage3 & (4'b0001 << lfsr_stage3[1:0]);
        end else begin
            grant <= 0;
        end
    end
end

endmodule