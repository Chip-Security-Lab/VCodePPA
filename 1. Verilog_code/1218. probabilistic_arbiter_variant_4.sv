//SystemVerilog
module probabilistic_arbiter #(parameter WIDTH=4) (
    input clk, rst_n,
    input [WIDTH*4-1:0] weight_i,
    input [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
    // Extract weights - combinational
    wire [3:0] weights[0:WIDTH-1];
    genvar g;
    generate
        for(g=0; g<WIDTH; g=g+1) begin : gen_weights
            assign weights[g] = weight_i[(g*4+3):(g*4)];
        end
    endgenerate
    
    // Pipeline stage 1 registers (merged former stages 1 and 2)
    reg [WIDTH-1:0] req_stage1;
    reg valid_stage1;
    reg [15:0] accumulator_stage1[0:WIDTH-1];
    
    // Pipeline stage 2 registers (output stage - former stage 4)
    reg [1:0] max_idx_stage2;
    
    // Stage 1: Register inputs and calculate accumulators in one stage
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            req_stage1 <= 0;
            valid_stage1 <= 0;
            for(integer i=0; i<WIDTH; i=i+1) begin
                accumulator_stage1[i] <= 0;
            end
        end else begin
            req_stage1 <= req_i;
            valid_stage1 <= 1'b1; // Start pipeline after reset
            
            // Directly calculate accumulators based on inputs
            for(integer i=0; i<WIDTH; i=i+1) begin
                case(req_i[i])
                    1'b1: accumulator_stage1[i] <= {12'b0, weights[i]};
                    1'b0: accumulator_stage1[i] <= 0;
                endcase
            end
        end
    end
    
    // Stage 2: Find maximum and generate grant
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            max_idx_stage2 <= 0;
            grant_o <= 0;
        end else begin
            if(valid_stage1) begin
                // Find maximum using case statement based on comparison results
                casez({
                    accumulator_stage1[0] >= accumulator_stage1[1] && accumulator_stage1[0] >= accumulator_stage1[2] && accumulator_stage1[0] >= accumulator_stage1[3],
                    accumulator_stage1[1] >= accumulator_stage1[0] && accumulator_stage1[1] >= accumulator_stage1[2] && accumulator_stage1[1] >= accumulator_stage1[3],
                    accumulator_stage1[2] >= accumulator_stage1[0] && accumulator_stage1[2] >= accumulator_stage1[1] && accumulator_stage1[2] >= accumulator_stage1[3]
                })
                    3'b1??: max_idx_stage2 <= 2'd0;
                    3'b01?: max_idx_stage2 <= 2'd1;
                    3'b001: max_idx_stage2 <= 2'd2;
                    3'b000: max_idx_stage2 <= 2'd3;
                endcase
                
                // Set grant
                grant_o <= (1 << max_idx_stage2);
            end
        end
    end
endmodule