//SystemVerilog
//IEEE 1364-2005 Verilog标准
module duty_cycle_clock_gate (
    input  wire clk_in,
    input  wire rst_n,
    input  wire [2:0] duty_ratio,
    output wire clk_out
);
    // Phase counter
    reg [2:0] phase;
    
    // Pipeline registers - reduced and optimized
    reg [2:0] duty_ratio_r;
    reg enable_gate;
    reg valid;
    
    // Stage 0: Counter logic with optimized comparison
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            phase <= 3'd0;
            duty_ratio_r <= 3'd0;
            enable_gate <= 1'b0;
            valid <= 1'b0;
        end
        else begin
            // Counter logic
            phase <= (phase == 3'd7) ? 3'd0 : phase + 1'b1;
            duty_ratio_r <= duty_ratio;
            
            // Directly compute gate enable signal in single stage
            // Optimized comparison - done in same cycle
            enable_gate <= (phase < duty_ratio_r);
            
            // Valid signal with single stage
            valid <= 1'b1;
        end
    end
    
    // Clock gating with simplified logic path
    assign clk_out = clk_in & (enable_gate | ~valid);
    
endmodule