//SystemVerilog
module DynamicWeightArbiter #(parameter DW=8) (
    input clk, rst,
    input [4*DW-1:0] dyn_weights,
    input [3:0] req,
    output reg [3:0] grant
);

// Stage 1: Weight Extraction and Accumulation
reg [DW-1:0] weight_array_stage1 [0:3];
reg [DW-1:0] acc_weights_stage1 [0:3];
reg [3:0] req_stage1;

// Stage 2: Weight Comparison
reg [DW-1:0] acc_weights_stage2 [0:3];
reg [3:0] req_stage2;
reg [3:0] grant_stage2;

// Extract individual weights
assign weight_array_stage1[0] = dyn_weights[0*DW +: DW];
assign weight_array_stage1[1] = dyn_weights[1*DW +: DW];
assign weight_array_stage1[2] = dyn_weights[2*DW +: DW];
assign weight_array_stage1[3] = dyn_weights[3*DW +: DW];

// Stage 1: Weight Accumulation
always @(posedge clk) begin
    if(rst) begin
        acc_weights_stage1[0] <= 0;
        acc_weights_stage1[1] <= 0;
        acc_weights_stage1[2] <= 0;
        acc_weights_stage1[3] <= 0;
        req_stage1 <= 0;
    end else begin
        acc_weights_stage1[0] <= acc_weights_stage1[0] + weight_array_stage1[0];
        acc_weights_stage1[1] <= acc_weights_stage1[1] + weight_array_stage1[1];
        acc_weights_stage1[2] <= acc_weights_stage1[2] + weight_array_stage1[2];
        acc_weights_stage1[3] <= acc_weights_stage1[3] + weight_array_stage1[3];
        req_stage1 <= req;
    end
end

// Stage 2: Weight Comparison and Grant Generation
always @(posedge clk) begin
    if(rst) begin
        acc_weights_stage2[0] <= 0;
        acc_weights_stage2[1] <= 0;
        acc_weights_stage2[2] <= 0;
        acc_weights_stage2[3] <= 0;
        req_stage2 <= 0;
        grant_stage2 <= 0;
    end else begin
        acc_weights_stage2[0] <= acc_weights_stage1[0];
        acc_weights_stage2[1] <= acc_weights_stage1[1];
        acc_weights_stage2[2] <= acc_weights_stage1[2];
        acc_weights_stage2[3] <= acc_weights_stage1[3];
        req_stage2 <= req_stage1;

        if (acc_weights_stage1[0] > acc_weights_stage1[1] && 
            acc_weights_stage1[0] > acc_weights_stage1[2] && 
            acc_weights_stage1[0] > acc_weights_stage1[3])
            grant_stage2 <= 4'b0001 & req_stage1;
        else if (acc_weights_stage1[1] > acc_weights_stage1[0] && 
                 acc_weights_stage1[1] > acc_weights_stage1[2] && 
                 acc_weights_stage1[1] > acc_weights_stage1[3])
            grant_stage2 <= 4'b0010 & req_stage1;
        else if (acc_weights_stage1[2] > acc_weights_stage1[0] && 
                 acc_weights_stage1[2] > acc_weights_stage1[1] && 
                 acc_weights_stage1[2] > acc_weights_stage1[3])
            grant_stage2 <= 4'b0100 & req_stage1;
        else
            grant_stage2 <= 4'b1000 & req_stage1;
    end
end

// Output Stage
always @(posedge clk) begin
    if(rst)
        grant <= 0;
    else
        grant <= grant_stage2;
end

endmodule