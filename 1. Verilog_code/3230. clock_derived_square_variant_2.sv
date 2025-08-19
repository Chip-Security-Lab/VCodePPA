//SystemVerilog
module clock_derived_square(
    input main_clk,
    input reset,
    output reg [3:0] clk_div_out
);
    // Pipeline stage counters
    reg [7:0] div_counter_stage1;
    reg [7:0] div_counter_stage2;
    
    // Pipeline control signals
    reg valid_stage1, valid_stage2;
    
    // Stage 1: Counter increment
    always @(posedge main_clk) begin
        if (reset) begin
            div_counter_stage1 <= 8'd0;
            valid_stage1 <= 1'b0;
        end else begin
            div_counter_stage1 <= div_counter_stage1 + 8'd1;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: Pass counter values through pipeline
    always @(posedge main_clk) begin
        if (reset) begin
            div_counter_stage2 <= 8'd0;
            valid_stage2 <= 1'b0;
        end else begin
            div_counter_stage2 <= div_counter_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Output stage: Generate clock outputs
    always @(posedge main_clk) begin
        if (reset) begin
            clk_div_out <= 4'b0000;
        end else if (valid_stage2) begin
            // Generate different frequency outputs
            clk_div_out[0] <= div_counter_stage2[0];  // Divide by 2
            clk_div_out[1] <= div_counter_stage2[1];  // Divide by 4
            clk_div_out[2] <= div_counter_stage2[3];  // Divide by 16
            clk_div_out[3] <= div_counter_stage2[5];  // Divide by 64
        end
    end
endmodule