//SystemVerilog
module oversample_adc (
    input clk, adc_in,
    output reg [7:0] adc_out
);
    // Pipeline stages for sum calculation
    reg [2:0] sum_stage1;
    reg [2:0] sum_stage2;
    reg [2:0] sum_stage3;
    reg [2:0] sum_stage4;
    
    // Additional pipeline stages for output calculation
    reg condition_stage1;
    reg condition_stage2;
    reg [7:0] adc_out_stage1;
    
    always @(posedge clk) begin
        // Stage 1: Initial sum accumulation
        sum_stage1 <= sum_stage4 + adc_in;
        
        // Stage 2-4: Pipelined buffering of sum signal
        sum_stage2 <= sum_stage1;
        sum_stage3 <= sum_stage2;
        sum_stage4 <= sum_stage3;
        
        // Output calculation pipeline
        // Stage 1: Condition check
        condition_stage1 <= &sum_stage4[2:0];
        
        // Stage 2: Shifted value calculation
        condition_stage2 <= condition_stage1;
        adc_out_stage1 <= sum_stage4[2:0] << 5;
        
        // Final output assignment
        if (condition_stage2) 
            adc_out <= adc_out_stage1;
    end
endmodule