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
reg valid_stage1;

// Stage 2: Weight Comparison
reg [DW-1:0] acc_weights_stage2 [0:3];
reg [3:0] req_stage2;
reg valid_stage2;

// Stage 3: Grant Generation
reg [3:0] grant_stage3;
reg valid_stage3;

// Stage 1 Logic
always @(posedge clk) begin
    if (rst) begin
        for (integer i = 0; i < 4; i = i + 1) begin
            acc_weights_stage1[i] <= 0;
            weight_array_stage1[i] <= 0;
        end
        valid_stage1 <= 0;
    end else begin
        for (integer i = 0; i < 4; i = i + 1) begin
            weight_array_stage1[i] <= dyn_weights[i*DW +: DW];
            acc_weights_stage1[i] <= acc_weights_stage1[i] + weight_array_stage1[i];
        end
        valid_stage1 <= 1;
    end
end

// Stage 2 Logic
always @(posedge clk) begin
    if (rst) begin
        for (integer i = 0; i < 4; i = i + 1)
            acc_weights_stage2[i] <= 0;
        req_stage2 <= 0;
        valid_stage2 <= 0;
    end else begin
        for (integer i = 0; i < 4; i = i + 1)
            acc_weights_stage2[i] <= acc_weights_stage1[i];
        req_stage2 <= req;
        valid_stage2 <= valid_stage1;
    end
end

// Stage 3 Logic
always @(posedge clk) begin
    if (rst) begin
        grant_stage3 <= 0;
        valid_stage3 <= 0;
    end else begin
        if (valid_stage2) begin
            reg [1:0] max_idx;
            reg [DW-1:0] max_weight;
            
            max_idx = 0;
            max_weight = acc_weights_stage2[0];
            
            for (integer i = 1; i < 4; i = i + 1) begin
                if (acc_weights_stage2[i] > max_weight) begin
                    max_idx = i;
                    max_weight = acc_weights_stage2[i];
                end
            end
            
            grant_stage3 <= (4'b0001 << max_idx) & req_stage2;
        end
        valid_stage3 <= valid_stage2;
    end
end

// Output Assignment
always @(posedge clk) begin
    if (rst)
        grant <= 0;
    else
        grant <= grant_stage3;
end

endmodule