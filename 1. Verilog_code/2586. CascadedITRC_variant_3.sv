//SystemVerilog
module CascadedITRC (
    input wire clock, resetn,
    input wire [1:0] top_level_irq,
    input wire [3:0] low_level_irq0,
    input wire [3:0] low_level_irq1,
    output reg master_irq,
    output reg [2:0] irq_vector
);

    // Buffered input signals
    reg [1:0] top_level_irq_buf;
    reg [3:0] low_level_irq0_buf;
    reg [3:0] low_level_irq1_buf;
    
    // Combinational signals
    wire [1:0] low_level_active;
    wire [2:0] next_low_priority [0:1];
    wire next_master_irq;
    wire [2:0] next_irq_vector;
    
    // Buffered control signals
    reg [1:0] low_level_active_buf;
    reg [2:0] next_low_priority_buf [0:1];
    reg next_master_irq_buf;
    reg [2:0] next_irq_vector_buf;

    // Input buffering
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

    // Combinational logic with buffered inputs
    assign low_level_active[0] = |low_level_irq0_buf;
    assign low_level_active[1] = |low_level_irq1_buf;

    // Priority calculation for low-level group 0
    assign next_low_priority[0] = low_level_irq0_buf[3] ? 3'd3 :
                                low_level_irq0_buf[2] ? 3'd2 :
                                low_level_irq0_buf[1] ? 3'd1 :
                                low_level_irq0_buf[0] ? 3'd0 : 3'd0;

    // Priority calculation for low-level group 1
    assign next_low_priority[1] = low_level_irq1_buf[3] ? 3'd3 :
                                low_level_irq1_buf[2] ? 3'd2 :
                                low_level_irq1_buf[1] ? 3'd1 :
                                low_level_irq1_buf[0] ? 3'd0 : 3'd0;

    // Master interrupt and vector generation
    assign next_master_irq = |(top_level_irq_buf & low_level_active);
    assign next_irq_vector = (top_level_irq_buf[1] && low_level_active[1]) ? {1'b1, next_low_priority[1]} :
                           (top_level_irq_buf[0] && low_level_active[0]) ? {1'b0, next_low_priority[0]} : 3'd0;

    // Control signal buffering
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            low_level_active_buf <= 0;
            next_low_priority_buf[0] <= 0;
            next_low_priority_buf[1] <= 0;
            next_master_irq_buf <= 0;
            next_irq_vector_buf <= 0;
        end else begin
            low_level_active_buf <= low_level_active;
            next_low_priority_buf[0] <= next_low_priority[0];
            next_low_priority_buf[1] <= next_low_priority[1];
            next_master_irq_buf <= next_master_irq;
            next_irq_vector_buf <= next_irq_vector;
        end
    end

    // Sequential logic with buffered control signals
    reg [2:0] low_priority [0:1];
    
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            master_irq <= 0;
            irq_vector <= 0;
            low_priority[0] <= 0;
            low_priority[1] <= 0;
        end else begin
            master_irq <= next_master_irq_buf;
            irq_vector <= next_irq_vector_buf;
            low_priority[0] <= next_low_priority_buf[0];
            low_priority[1] <= next_low_priority_buf[1];
        end
    end

endmodule