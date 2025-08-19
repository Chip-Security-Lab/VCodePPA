//SystemVerilog
module quad_clock_gen(
    input clock_in,
    input reset,
    output reg clock_0,
    output reg clock_90,
    output reg clock_180,
    output reg clock_270
);
    // Pipeline stage 1: Counter logic
    reg [1:0] phase_counter_stage1;
    
    // Pipeline stage 2: Comparison results
    reg comp_0_stage2;
    reg comp_90_stage2;
    reg comp_180_stage2;
    reg comp_270_stage2;
    
    // Pipeline stage 1: Counter operation
    always @(posedge clock_in or posedge reset) begin
        if (reset)
            phase_counter_stage1 <= 2'b00;
        else
            phase_counter_stage1 <= phase_counter_stage1 + 1'b1;
    end
    
    // Pipeline stage 2: Comparisons
    always @(posedge clock_in or posedge reset) begin
        if (reset) begin
            comp_0_stage2 <= 1'b0;
            comp_90_stage2 <= 1'b0;
            comp_180_stage2 <= 1'b0;
            comp_270_stage2 <= 1'b0;
        end
        else begin
            comp_0_stage2 <= (phase_counter_stage1 == 2'b00);
            comp_90_stage2 <= (phase_counter_stage1 == 2'b01);
            comp_180_stage2 <= (phase_counter_stage1 == 2'b10);
            comp_270_stage2 <= (phase_counter_stage1 == 2'b11);
        end
    end
    
    // Pipeline stage 3: Output registers
    always @(posedge clock_in or posedge reset) begin
        if (reset) begin
            clock_0 <= 1'b0;
            clock_90 <= 1'b0;
            clock_180 <= 1'b0;
            clock_270 <= 1'b0;
        end
        else begin
            clock_0 <= comp_0_stage2;
            clock_90 <= comp_90_stage2;
            clock_180 <= comp_180_stage2;
            clock_270 <= comp_270_stage2;
        end
    end
endmodule