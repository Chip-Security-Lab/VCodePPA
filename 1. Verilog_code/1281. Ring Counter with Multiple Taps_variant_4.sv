//SystemVerilog
module tapped_ring_counter(
    input wire clock,
    input wire reset,
    input wire enable,      // Pipeline enable signal
    output reg [3:0] state_stage2,
    output wire tap1, tap2  // Tapped outputs
);
    // Pipeline stage 1
    reg [3:0] state_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 valid signal
    reg valid_stage2;
    
    // Optimize tapped output assignments using direct bit selection
    assign tap1 = state_stage2[1];
    assign tap2 = state_stage2[3];
    
    // Optimized pipeline logic for stage 1
    always @(posedge clock) begin
        if (reset) begin
            state_stage1 <= 4'b0001;
            valid_stage1 <= 1'b0;
        end 
        else if (enable) begin
            // Optimized rotation using concatenation
            state_stage1 <= {state_stage2[2:0], state_stage2[3]};
            valid_stage1 <= 1'b1;
        end
    end
    
    // Optimized pipeline logic for stage 2
    always @(posedge clock) begin
        if (reset) begin
            state_stage2 <= 4'b0001;
            valid_stage2 <= 1'b0;
        end 
        else if (enable) begin
            // Direct register transfer
            state_stage2 <= state_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
endmodule