module AdaptiveITRC #(parameter WIDTH=4) (
    input wire clk, rst,
    input wire [WIDTH-1:0] irq_in,
    input wire ack,
    output reg irq_out,
    output reg [1:0] irq_id
);
    reg [3:0] occurrence_count [0:WIDTH-1];
    reg [1:0] priority_order [0:WIDTH-1];
    
    integer i;
    initial begin
        for (i = 0; i < WIDTH; i = i + 1) begin
            occurrence_count[i] = 0;
            priority_order[i] = i; // Default order
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            irq_out <= 0;
            irq_id <= 0;
            for (i = 0; i < WIDTH; i = i + 1) begin
                occurrence_count[i] <= 0;
                priority_order[i] <= i; // Default order
            end
        end else begin
            // Count occurrences of each interrupt
            if (irq_in[0]) occurrence_count[0] <= occurrence_count[0] + 1;
            if (irq_in[1]) occurrence_count[1] <= occurrence_count[1] + 1;
            if (irq_in[2]) occurrence_count[2] <= occurrence_count[2] + 1;
            if (irq_in[3]) occurrence_count[3] <= occurrence_count[3] + 1;
            
            // Use the priority order to select active interrupt
            irq_out <= 0;
            if (irq_in[priority_order[0]]) begin
                irq_out <= 1;
                irq_id <= priority_order[0];
            end else if (irq_in[priority_order[1]]) begin
                irq_out <= 1;
                irq_id <= priority_order[1];
            end else if (irq_in[priority_order[2]]) begin
                irq_out <= 1;
                irq_id <= priority_order[2];
            end else if (irq_in[priority_order[3]]) begin
                irq_out <= 1;
                irq_id <= priority_order[3];
            end
            
            // Update priority order based on occurrence counts
            if (occurrence_count[0] > occurrence_count[1] && 
                occurrence_count[0] > occurrence_count[2] && 
                occurrence_count[0] > occurrence_count[3]) begin
                priority_order[0] <= 0;
            end else if (occurrence_count[1] > occurrence_count[0] && 
                        occurrence_count[1] > occurrence_count[2] && 
                        occurrence_count[1] > occurrence_count[3]) begin
                priority_order[0] <= 1;
            end else if (occurrence_count[2] > occurrence_count[0] && 
                        occurrence_count[2] > occurrence_count[1] && 
                        occurrence_count[2] > occurrence_count[3]) begin
                priority_order[0] <= 2;
            end else if (occurrence_count[3] > occurrence_count[0] && 
                        occurrence_count[3] > occurrence_count[1] && 
                        occurrence_count[3] > occurrence_count[2]) begin
                priority_order[0] <= 3;
            end
            
            // Clear output on acknowledge
            if (ack) irq_out <= 0;
        end
    end
endmodule