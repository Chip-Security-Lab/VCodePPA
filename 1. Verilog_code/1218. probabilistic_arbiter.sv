module probabilistic_arbiter #(parameter WIDTH=4) (
    input clk, rst_n,
    input [WIDTH*4-1:0] weight_i,
    input [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
    reg [15:0] accumulator[0:WIDTH-1];
    reg [1:0] max_idx;
    
    // Extract weights
    wire [3:0] weights[0:WIDTH-1];
    genvar g;
    generate
        for(g=0; g<WIDTH; g=g+1) begin : gen_weights
            assign weights[g] = weight_i[(g*4+3):(g*4)];
        end
    endgenerate
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            grant_o <= 0;
            accumulator[0] <= 0;
            accumulator[1] <= 0;
            accumulator[2] <= 0;
            accumulator[3] <= 0;
            max_idx <= 0;
        end else begin
            // Update accumulators
            if(req_i[0]) accumulator[0] <= accumulator[0] + {12'b0, weights[0]};
            else accumulator[0] <= 0;
            
            if(req_i[1]) accumulator[1] <= accumulator[1] + {12'b0, weights[1]};
            else accumulator[1] <= 0;
            
            if(req_i[2]) accumulator[2] <= accumulator[2] + {12'b0, weights[2]};
            else accumulator[2] <= 0;
            
            if(req_i[3]) accumulator[3] <= accumulator[3] + {12'b0, weights[3]};
            else accumulator[3] <= 0;
            
            // Find maximum
            if(accumulator[0] >= accumulator[1] && accumulator[0] >= accumulator[2] && accumulator[0] >= accumulator[3])
                max_idx <= 2'd0;
            else if(accumulator[1] >= accumulator[0] && accumulator[1] >= accumulator[2] && accumulator[1] >= accumulator[3])
                max_idx <= 2'd1;
            else if(accumulator[2] >= accumulator[0] && accumulator[2] >= accumulator[1] && accumulator[2] >= accumulator[3])
                max_idx <= 2'd2;
            else
                max_idx <= 2'd3;
                
            // Set grant
            grant_o <= (1 << max_idx);
        end
    end
endmodule