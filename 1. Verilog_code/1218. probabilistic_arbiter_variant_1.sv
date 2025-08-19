//SystemVerilog
module probabilistic_arbiter #(parameter WIDTH=4) (
    input clk, rst_n,
    input [WIDTH*4-1:0] weight_i,
    input [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
    // Stage 1: Extract weights and update accumulators
    reg [15:0] accumulator_stage1[0:WIDTH-1];
    reg [WIDTH-1:0] req_stage1;
    
    // Stage 2: Find maximum (comparison first level)
    reg [15:0] accumulator_stage2[0:WIDTH-1];
    reg [WIDTH-1:0] req_stage2;
    reg [1:0] max_idx_level1_a; // For 0 vs 1
    reg [1:0] max_idx_level1_b; // For 2 vs 3
    reg [15:0] max_val_level1_a;
    reg [15:0] max_val_level1_b;
    
    // Stage 3: Find maximum (comparison second level) and set grant
    reg [1:0] max_idx_stage3;
    
    // Extract weights
    wire [3:0] weights[0:WIDTH-1];
    genvar g;
    generate
        for(g=0; g<WIDTH; g=g+1) begin : gen_weights
            assign weights[g] = weight_i[(g*4+3):(g*4)];
        end
    endgenerate
    
    // Stage 1: Reset handling
    always @(negedge rst_n) begin
        if(!rst_n) begin
            accumulator_stage1[0] <= 0;
            accumulator_stage1[1] <= 0;
            accumulator_stage1[2] <= 0;
            accumulator_stage1[3] <= 0;
            req_stage1 <= 0;
        end
    end
    
    // Stage 1: Req register update
    always @(posedge clk) begin
        if(rst_n) begin
            req_stage1 <= req_i;
        end
    end
    
    // Stage 1: Accumulator update for channel 0
    always @(posedge clk) begin
        if(rst_n) begin
            if(req_i[0]) 
                accumulator_stage1[0] <= {12'b0, weights[0]};
            else 
                accumulator_stage1[0] <= 0;
        end
    end
    
    // Stage 1: Accumulator update for channel 1
    always @(posedge clk) begin
        if(rst_n) begin
            if(req_i[1]) 
                accumulator_stage1[1] <= {12'b0, weights[1]};
            else 
                accumulator_stage1[1] <= 0;
        end
    end
    
    // Stage 1: Accumulator update for channel 2
    always @(posedge clk) begin
        if(rst_n) begin
            if(req_i[2]) 
                accumulator_stage1[2] <= {12'b0, weights[2]};
            else 
                accumulator_stage1[2] <= 0;
        end
    end
    
    // Stage 1: Accumulator update for channel 3
    always @(posedge clk) begin
        if(rst_n) begin
            if(req_i[3]) 
                accumulator_stage1[3] <= {12'b0, weights[3]};
            else 
                accumulator_stage1[3] <= 0;
        end
    end
    
    // Stage 2: Reset handling
    always @(negedge rst_n) begin
        if(!rst_n) begin
            accumulator_stage2[0] <= 0;
            accumulator_stage2[1] <= 0;
            accumulator_stage2[2] <= 0;
            accumulator_stage2[3] <= 0;
            req_stage2 <= 0;
            max_idx_level1_a <= 0;
            max_idx_level1_b <= 2;
            max_val_level1_a <= 0;
            max_val_level1_b <= 0;
        end
    end
    
    // Stage 2: Pass values to next stage
    always @(posedge clk) begin
        if(rst_n) begin
            accumulator_stage2[0] <= accumulator_stage1[0];
            accumulator_stage2[1] <= accumulator_stage1[1];
            accumulator_stage2[2] <= accumulator_stage1[2];
            accumulator_stage2[3] <= accumulator_stage1[3];
            req_stage2 <= req_stage1;
        end
    end
    
    // Stage 2: Compare channel 0 vs channel 1
    always @(posedge clk) begin
        if(rst_n) begin
            if(accumulator_stage1[0] >= accumulator_stage1[1]) begin
                max_idx_level1_a <= 2'd0;
                max_val_level1_a <= accumulator_stage1[0];
            end else begin
                max_idx_level1_a <= 2'd1;
                max_val_level1_a <= accumulator_stage1[1];
            end
        end
    end
    
    // Stage 2: Compare channel 2 vs channel 3
    always @(posedge clk) begin
        if(rst_n) begin
            if(accumulator_stage1[2] >= accumulator_stage1[3]) begin
                max_idx_level1_b <= 2'd2;
                max_val_level1_b <= accumulator_stage1[2];
            end else begin
                max_idx_level1_b <= 2'd3;
                max_val_level1_b <= accumulator_stage1[3];
            end
        end
    end
    
    // Stage 3: Reset handling
    always @(negedge rst_n) begin
        if(!rst_n) begin
            max_idx_stage3 <= 0;
            grant_o <= 0;
        end
    end
    
    // Stage 3: Final comparison 
    always @(posedge clk) begin
        if(rst_n) begin
            if(max_val_level1_a >= max_val_level1_b) begin
                max_idx_stage3 <= max_idx_level1_a;
            end else begin
                max_idx_stage3 <= max_idx_level1_b;
            end
        end
    end
    
    // Stage 3: Grant generation
    always @(posedge clk) begin
        if(rst_n) begin
            grant_o <= (1'b1 << max_idx_stage3);
        end
    end
endmodule