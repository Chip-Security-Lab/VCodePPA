//SystemVerilog
module CascadedITRC (
    input wire clock, resetn,
    input wire [1:0] top_level_irq,
    input wire [3:0] low_level_irq0,
    input wire [3:0] low_level_irq1,
    output reg master_irq,
    output reg [2:0] irq_vector
);
    // Buffer registers for high fanout signals
    reg [1:0] top_level_irq_buf;
    reg [3:0] low_level_irq0_buf;
    reg [3:0] low_level_irq1_buf;
    reg [1:0] low_level_active;
    reg [1:0] low_level_active_buf;
    reg [2:0] low_priority [0:1];
    reg [2:0] low_priority_buf [0:1];
    
    // First stage: Buffer high fanout inputs
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            top_level_irq_buf <= 0;
            low_level_irq0_buf <= 0;
            low_level_irq1_buf <= 0;
        end else begin
            top_level_irq_buf <= top_level_irq;
            low_level_irq0_buf <= low_level_irq0;
            low_level_irq1_buf <= low_level_irq1;
        end
    end
    
    // Second stage: Calculate active signals and priorities
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            low_level_active <= 0;
            low_priority[0] <= 0;
            low_priority[1] <= 0;
        end else begin
            // Calculate active signals and priorities for low-level group 0
            low_level_active[0] <= |low_level_irq0_buf;
            low_priority[0] <= low_level_irq0_buf[3] ? 3'd3 :
                             low_level_irq0_buf[2] ? 3'd2 :
                             low_level_irq0_buf[1] ? 3'd1 :
                             low_level_irq0_buf[0] ? 3'd0 : 3'd0;
            
            // Calculate active signals and priorities for low-level group 1
            low_level_active[1] <= |low_level_irq1_buf;
            low_priority[1] <= low_level_irq1_buf[3] ? 3'd3 :
                             low_level_irq1_buf[2] ? 3'd2 :
                             low_level_irq1_buf[1] ? 3'd1 :
                             low_level_irq1_buf[0] ? 3'd0 : 3'd0;
        end
    end
    
    // Third stage: Buffer active signals and priorities
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            low_level_active_buf <= 0;
            low_priority_buf[0] <= 0;
            low_priority_buf[1] <= 0;
        end else begin
            low_level_active_buf <= low_level_active;
            low_priority_buf[0] <= low_priority[0];
            low_priority_buf[1] <= low_priority[1];
        end
    end
    
    // Final stage: Generate outputs
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            master_irq <= 0;
            irq_vector <= 0;
        end else begin
            master_irq <= |(top_level_irq_buf & low_level_active_buf);
            irq_vector <= (top_level_irq_buf[1] && low_level_active_buf[1]) ? {1'b1, low_priority_buf[1]} :
                         (top_level_irq_buf[0] && low_level_active_buf[0]) ? {1'b0, low_priority_buf[0]} : 3'd0;
        end
    end
endmodule