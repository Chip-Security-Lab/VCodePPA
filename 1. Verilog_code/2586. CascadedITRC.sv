module CascadedITRC (
    input wire clock, resetn,
    input wire [1:0] top_level_irq,
    input wire [3:0] low_level_irq0,
    input wire [3:0] low_level_irq1,
    output reg master_irq,
    output reg [2:0] irq_vector
);
    wire [1:0] low_level_active;
    reg [2:0] low_priority [0:1];
    
    assign low_level_active[0] = |low_level_irq0;
    assign low_level_active[1] = |low_level_irq1;
    
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            master_irq <= 0;
            irq_vector <= 0;
            low_priority[0] <= 0;
            low_priority[1] <= 0;
        end else begin
            // Calculate priorities for low-level group 0
            if (low_level_irq0[3]) low_priority[0] <= 3;
            else if (low_level_irq0[2]) low_priority[0] <= 2;
            else if (low_level_irq0[1]) low_priority[0] <= 1;
            else if (low_level_irq0[0]) low_priority[0] <= 0;
            
            // Calculate priorities for low-level group 1
            if (low_level_irq1[3]) low_priority[1] <= 3;
            else if (low_level_irq1[2]) low_priority[1] <= 2;
            else if (low_level_irq1[1]) low_priority[1] <= 1;
            else if (low_level_irq1[0]) low_priority[1] <= 0;
            
            // Determine if any interrupt is active and its vector
            master_irq <= |(top_level_irq & low_level_active);
            if (top_level_irq[1] && low_level_active[1])
                irq_vector <= {1'b1, low_priority[1]};
            else if (top_level_irq[0] && low_level_active[0])
                irq_vector <= {1'b0, low_priority[0]};
        end
    end
endmodule