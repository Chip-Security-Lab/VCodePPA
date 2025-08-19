//SystemVerilog
module output_enabled_ring_counter(
    input wire clock,
    input wire reset,
    input wire oe, // Output enable
    output wire [3:0] data
);
    // Pipeline stage 1 - counter logic with optimization
    reg [3:0] count_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 - output logic
    reg [3:0] count_stage2;
    reg oe_stage2;
    reg valid_stage2;
    
    // Registered input
    reg oe_stage1;
    
    // Pre-compute next count value (retimed forward)
    wire [3:0] next_count = {count_stage1[2:0], count_stage1[3]};
    
    // Stage 1: Counter logic with retimed register
    always @(posedge clock) begin
        if (reset) begin
            count_stage1 <= 4'b0001;
            valid_stage1 <= 1'b0;
            oe_stage1 <= 1'b0;
        end
        else begin
            count_stage1 <= next_count;
            valid_stage1 <= 1'b1;
            oe_stage1 <= oe;
        end
    end
    
    // Stage 2: Output logic
    always @(posedge clock) begin
        if (reset) begin
            count_stage2 <= 4'b0000;
            oe_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end
        else begin
            count_stage2 <= count_stage1;
            oe_stage2 <= oe_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Three-state output - using pipeline stage 2 signals
    assign data = (valid_stage2 && oe_stage2) ? count_stage2 : 4'bz;
    
endmodule