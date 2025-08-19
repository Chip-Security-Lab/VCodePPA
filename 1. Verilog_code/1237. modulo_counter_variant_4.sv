//SystemVerilog
module modulo_counter #(parameter MOD_VALUE = 10, WIDTH = 4) (
    input wire clk, reset,
    input wire enable,
    output reg [WIDTH-1:0] count,
    output reg tc,
    output reg valid_out
);
    // Pipeline stage 1 registers
    reg [WIDTH-1:0] count_stage1;
    reg valid_stage1;
    wire tc_stage1;
    
    // Pipeline stage 2 registers
    reg [WIDTH-1:0] count_stage2;
    reg valid_stage2;
    reg tc_stage2;
    
    // Pre-compute the terminal count comparison value
    localparam [WIDTH-1:0] TC_VALUE = MOD_VALUE - 1;
    
    // Stage 1: Optimized terminal count check
    assign tc_stage1 = (count_stage1 == TC_VALUE);
    
    // Pipeline control
    always @(posedge clk) begin
        if (reset) begin
            // Reset all pipeline registers in a single block
            count_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
            count_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
            tc_stage2 <= 1'b0;
            count <= {WIDTH{1'b0}};
            tc <= 1'b0;
            valid_out <= 1'b0;
        end
        else begin
            // Stage 1: Input registration
            valid_stage1 <= enable;
            if (enable) begin
                count_stage1 <= count;
            end
                
            // Stage 2: Calculation results with optimized conditional logic
            valid_stage2 <= valid_stage1;
            if (valid_stage1) begin
                count_stage2 <= tc_stage1 ? {WIDTH{1'b0}} : count_stage1 + 1'b1;
                tc_stage2 <= tc_stage1;
            end
            
            // Output stage
            valid_out <= valid_stage2;
            if (valid_stage2) begin
                count <= count_stage2;
                tc <= tc_stage2;
            end
        end
    end
endmodule