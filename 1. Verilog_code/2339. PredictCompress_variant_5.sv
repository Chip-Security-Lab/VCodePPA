//SystemVerilog
module PredictCompress (
    input clk, en, rst_n,
    input [15:0] current,
    input valid_in,
    output reg valid_out,
    output reg [7:0] delta,
    output reg ready_in
);
    // Pipeline Stage 1 registers
    reg [15:0] current_stage1;
    reg [15:0] prev;
    reg valid_stage1;
    
    // Pipeline Stage 2 registers
    reg [15:0] current_stage2;
    reg [15:0] prev_stage2;
    reg valid_stage2;
    
    // Intermediate computation result
    wire [7:0] delta_comb;
    
    // Calculate delta combinationally between stage 2 registers
    assign delta_comb = current_stage2 - prev_stage2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all pipeline registers
            current_stage1 <= 16'b0;
            prev <= 16'b0;
            valid_stage1 <= 1'b0;
            
            current_stage2 <= 16'b0;
            prev_stage2 <= 16'b0;
            valid_stage2 <= 1'b0;
            
            delta <= 8'b0;
            valid_out <= 1'b0;
            ready_in <= 1'b1;
        end else if (en) begin
            // Stage 1: Input capture and previous value management
            if (valid_in && ready_in) begin
                current_stage1 <= current;
                valid_stage1 <= 1'b1;
                prev <= current_stage1;  // Update prev with last current
            end else if (!valid_in) begin
                valid_stage1 <= 1'b0;
            end
            
            // Stage 2: Prepare for delta calculation
            current_stage2 <= current_stage1;
            prev_stage2 <= prev;
            valid_stage2 <= valid_stage1;
            
            // Stage 3: Output delta result
            if (valid_stage2) begin
                delta <= delta_comb;
                valid_out <= 1'b1;
            end else begin
                valid_out <= 1'b0;
            end
            
            // Ready signal logic - simplistic backpressure handling
            ready_in <= 1'b1;  // Always ready in this implementation
        end
    end
endmodule