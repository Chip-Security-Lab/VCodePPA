module TimeSlicedITRC #(parameter TIMESLOTS=4) (
    input wire clk, rst_n,
    input wire [TIMESLOTS-1:0] irq_sources,
    input wire [1:0] timeslot_width [TIMESLOTS-1:0],
    output reg active_irq,
    output reg [1:0] active_slot
);
    reg [2:0] slot_counter;
    reg [2:0] current_slot;
    reg [2:0] slot_width;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            slot_counter <= 0;
            current_slot <= 0;
            active_irq <= 0;
            active_slot <= 0;
            slot_width <= timeslot_width[0];
        end else begin
            // Update slot counter
            if (slot_counter < slot_width)
                slot_counter <= slot_counter + 1;
            else begin
                slot_counter <= 0;
                current_slot <= (current_slot + 1) % TIMESLOTS;
                slot_width <= timeslot_width[current_slot];
            end
            
            // Check if current slot has an active interrupt
            if (irq_sources[current_slot]) begin
                active_irq <= 1;
                active_slot <= current_slot;
            end else begin
                active_irq <= 0;
            end
        end
    end
endmodule