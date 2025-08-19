//SystemVerilog
module basic_ring_counter #(parameter WIDTH = 4)(
    input wire clk,
    input wire rst_n,
    input wire enable,
    output reg [WIDTH-1:0] count,
    output reg valid_out
);
    // Pipeline registers with reset and enable logic
    reg [WIDTH-1:0] count_stage [1:0];
    reg valid_stage [1:0];
    
    // One-hot encoding initialization
    initial begin
        count = {{(WIDTH-1){1'b0}}, 1'b1};
        count_stage[0] = {{(WIDTH-1){1'b0}}, 1'b1};
        count_stage[1] = {{(WIDTH-1){1'b0}}, 1'b1};
        valid_stage[0] = 1'b0;
        valid_stage[1] = 1'b0;
        valid_out = 1'b0;
    end
    
    // Combined pipeline logic with optimized reset handling
    always @(posedge clk) begin
        if (!rst_n) begin
            // Reset all pipeline stages simultaneously
            count_stage[0] <= {{(WIDTH-1){1'b0}}, 1'b1};
            count_stage[1] <= {{(WIDTH-1){1'b0}}, 1'b1};
            count <= {{(WIDTH-1){1'b0}}, 1'b1};
            
            valid_stage[0] <= 1'b0;
            valid_stage[1] <= 1'b0;
            valid_out <= 1'b0;
        end 
        else if (enable) begin
            // Stage 1: Compute rotation using efficient bit manipulation
            count_stage[0] <= {count[WIDTH-2:0], count[WIDTH-1]};
            valid_stage[0] <= 1'b1;
            
            // Stage 2: Pass through from stage 1
            count_stage[1] <= count_stage[0];
            valid_stage[1] <= valid_stage[0];
            
            // Output stage: Pass through from stage 2
            count <= count_stage[1];
            valid_out <= valid_stage[1];
        end
    end
endmodule