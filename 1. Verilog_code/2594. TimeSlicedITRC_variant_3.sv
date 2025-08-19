//SystemVerilog
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
    reg [2:0] next_slot;
    reg [2:0] next_counter;
    reg [2:0] next_width;
    reg [2:0] current_slot_d;
    reg [TIMESLOTS-1:0] irq_sources_d;
    reg irq_detected;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            slot_counter <= 0;
            current_slot <= 0;
            slot_width <= timeslot_width[0];
            current_slot_d <= 0;
            irq_sources_d <= 0;
            irq_detected <= 0;
            active_irq <= 0;
            active_slot <= 0;
        end else begin
            // Stage 1: Counter and slot management
            if (slot_counter < slot_width) begin
                next_counter = slot_counter + 1;
                next_slot = current_slot;
                next_width = slot_width;
            end else begin
                next_counter = 0;
                next_slot = (current_slot + 1) % TIMESLOTS;
                next_width = timeslot_width[current_slot];
            end
            
            // Stage 1 registers
            slot_counter <= next_counter;
            current_slot <= next_slot;
            slot_width <= next_width;
            
            // Stage 2: Interrupt detection
            current_slot_d <= current_slot;
            irq_sources_d <= irq_sources;
            irq_detected <= irq_sources[current_slot];
            
            // Stage 2 output
            active_irq <= irq_detected;
            active_slot <= current_slot_d;
        end
    end
endmodule