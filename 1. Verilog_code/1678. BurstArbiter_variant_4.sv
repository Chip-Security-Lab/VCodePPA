//SystemVerilog
module BurstArbiter #(parameter BURST_LEN=4) (
    input clk, rst, en,
    input [3:0] req,
    output reg [3:0] grant
);

// Pipeline stage 1 - Request processing
reg [3:0] req_stage1;
reg en_stage1;
reg [3:0] grant_stage1;
reg [1:0] burst_cnt_stage1;

// Pipeline stage 2 - Grant generation
reg [3:0] grant_stage2;
reg [1:0] burst_cnt_stage2;
reg valid_stage2;

// Pipeline stage 3 - Output
reg [3:0] grant_stage3;
reg valid_stage3;

// Stage 1 logic
wire [3:0] next_grant_stage1 = req & ~req;
wire burst_end_stage1 = (burst_cnt_stage1 == BURST_LEN-1);
wire [3:0] grant_hold_stage1 = burst_end_stage1 ? next_grant_stage1 : grant_stage1;
wire [1:0] next_cnt_stage1 = burst_end_stage1 ? 2'b0 : burst_cnt_stage1 + 1'b1;

// Stage 1 registers
always @(posedge clk) begin
    if(rst) begin
        req_stage1 <= 4'b0;
        en_stage1 <= 1'b0;
        grant_stage1 <= 4'b0;
        burst_cnt_stage1 <= 2'b0;
    end
    else begin
        req_stage1 <= req;
        en_stage1 <= en;
        if(en) begin
            if(|grant_stage1) begin
                grant_stage1 <= grant_hold_stage1;
                burst_cnt_stage1 <= next_cnt_stage1;
            end
            else begin
                grant_stage1 <= next_grant_stage1;
                burst_cnt_stage1 <= 2'b0;
            end
        end
    end
end

// Stage 2 logic
wire [3:0] grant_hold_stage2 = (burst_cnt_stage2 == BURST_LEN-1) ? 
                              (req_stage1 & ~req_stage1) : grant_stage2;

// Stage 2 registers
always @(posedge clk) begin
    if(rst) begin
        grant_stage2 <= 4'b0;
        burst_cnt_stage2 <= 2'b0;
        valid_stage2 <= 1'b0;
    end
    else if(en_stage1) begin
        grant_stage2 <= grant_hold_stage2;
        burst_cnt_stage2 <= (burst_cnt_stage2 == BURST_LEN-1) ? 2'b0 : burst_cnt_stage2 + 1'b1;
        valid_stage2 <= 1'b1;
    end
    else begin
        valid_stage2 <= 1'b0;
    end
end

// Stage 3 - Output stage
always @(posedge clk) begin
    if(rst) begin
        grant_stage3 <= 4'b0;
        valid_stage3 <= 1'b0;
    end
    else if(valid_stage2) begin
        grant_stage3 <= grant_stage2;
        valid_stage3 <= 1'b1;
    end
    else begin
        valid_stage3 <= 1'b0;
    end
end

// Output assignment
assign grant = grant_stage3;

endmodule