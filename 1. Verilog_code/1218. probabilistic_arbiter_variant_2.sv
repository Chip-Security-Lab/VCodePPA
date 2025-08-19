//SystemVerilog
module probabilistic_arbiter #(parameter WIDTH=4) (
    input clk, rst_n,
    input [WIDTH*4-1:0] weight_i,
    input [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
    reg [15:0] accumulator[0:WIDTH-1];
    reg [15:0] acc_pipe[0:WIDTH-1];
    reg [5:0] compare_results;
    reg [1:0] max_idx, max_idx_pipe;
    
    // Extract weights
    wire [3:0] weights[0:WIDTH-1];
    genvar g;
    generate
        for(g=0; g<WIDTH; g=g+1) begin : gen_weights
            assign weights[g] = weight_i[(g*4+3):(g*4)];
        end
    endgenerate
    
    // Stage 1: Update accumulators
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            accumulator[0] <= 0;
            accumulator[1] <= 0;
            accumulator[2] <= 0;
            accumulator[3] <= 0;
        end else begin
            // Update accumulator for each channel based on request
            if(req_i[0]) accumulator[0] <= accumulator[0] + {12'b0, weights[0]};
            else accumulator[0] <= 0;
            
            if(req_i[1]) accumulator[1] <= accumulator[1] + {12'b0, weights[1]};
            else accumulator[1] <= 0;
            
            if(req_i[2]) accumulator[2] <= accumulator[2] + {12'b0, weights[2]};
            else accumulator[2] <= 0;
            
            if(req_i[3]) accumulator[3] <= accumulator[3] + {12'b0, weights[3]};
            else accumulator[3] <= 0;
        end
    end
    
    // Stage 1.5: Pipeline registers for accumulator values
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            acc_pipe[0] <= 0;
            acc_pipe[1] <= 0;
            acc_pipe[2] <= 0;
            acc_pipe[3] <= 0;
        end else begin
            acc_pipe[0] <= accumulator[0];
            acc_pipe[1] <= accumulator[1];
            acc_pipe[2] <= accumulator[2];
            acc_pipe[3] <= accumulator[3];
        end
    end
    
    // Stage 2: Calculate pairwise comparisons
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            compare_results <= 0;
        end else begin
            // Format: {0>=1, 0>=2, 0>=3, 1>=2, 1>=3, 2>=3}
            compare_results[0] <= (acc_pipe[0] >= acc_pipe[1]);
            compare_results[1] <= (acc_pipe[0] >= acc_pipe[2]);
            compare_results[2] <= (acc_pipe[0] >= acc_pipe[3]);
            compare_results[3] <= (acc_pipe[1] >= acc_pipe[2]);
            compare_results[4] <= (acc_pipe[1] >= acc_pipe[3]);
            compare_results[5] <= (acc_pipe[2] >= acc_pipe[3]);
        end
    end
    
    // Stage 3: Determine maximum value index based on comparison results
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            max_idx <= 0;
        end else begin
            if(compare_results[0] && compare_results[1] && compare_results[2])
                max_idx <= 2'd0;
            else if((!compare_results[0]) && compare_results[3] && compare_results[4])
                max_idx <= 2'd1;
            else if((!compare_results[1]) && (!compare_results[3]) && compare_results[5])
                max_idx <= 2'd2;
            else
                max_idx <= 2'd3;
        end
    end
    
    // Stage 3.5: Pipeline register for max_idx
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            max_idx_pipe <= 0;
        end else begin
            max_idx_pipe <= max_idx;
        end
    end
    
    // Stage 4: Set grant output
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            grant_o <= 0;
        end else begin
            grant_o <= (1 << max_idx_pipe);
        end
    end
endmodule