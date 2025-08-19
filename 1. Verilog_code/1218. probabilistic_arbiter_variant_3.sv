//SystemVerilog
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
    
    // Intermediate signals
    reg [15:0] next_accumulator[0:WIDTH-1];
    reg [1:0] next_max_idx;
    
    // Max comparison variables
    reg [15:0] max_value;
    reg [15:0] current_value;
    integer i;
    
    always @(*) begin
        // Calculate next accumulator values based on requests
        for(i = 0; i < WIDTH; i = i + 1) begin
            next_accumulator[i] = req_i[i] ? (accumulator[i] + {12'b0, weights[i]}) : 16'b0;
        end
        
        // Find maximum using a more efficient single-pass algorithm
        max_value = next_accumulator[0];
        next_max_idx = 2'd0;
        
        for(i = 1; i < WIDTH; i = i + 1) begin
            current_value = next_accumulator[i];
            if(current_value > max_value) begin
                max_value = current_value;
                next_max_idx = i[1:0];
            end
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant_o <= {WIDTH{1'b0}};
            max_idx <= 2'd0;
            for(i = 0; i < WIDTH; i = i + 1) begin
                accumulator[i] <= 16'b0;
            end
        end 
        else begin
            // Update accumulators
            for(i = 0; i < WIDTH; i = i + 1) begin
                accumulator[i] <= next_accumulator[i];
            end
            
            // Update max_idx
            max_idx <= next_max_idx;
                
            // Set grant using efficient bit shift
            grant_o <= (1'b1 << next_max_idx);
        end
    end
endmodule