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
    
    // Carry-lookahead adder signals
    wire [2:0] slot_counter_next;
    wire [2:0] current_slot_next;
    wire carry_out;
    
    // Generate and propagate signals for carry-lookahead
    wire [2:0] generate_signal;
    wire [2:0] propagate_signal;
    wire [2:0] carry_internal;
    
    // Generate signals
    assign generate_signal[0] = slot_counter[0] & 1'b1;
    assign generate_signal[1] = slot_counter[1] & slot_counter[0];
    assign generate_signal[2] = slot_counter[2] & slot_counter[1] & slot_counter[0];
    
    // Propagate signals
    assign propagate_signal[0] = slot_counter[0] | 1'b1;
    assign propagate_signal[1] = slot_counter[1] | slot_counter[0];
    assign propagate_signal[2] = slot_counter[2] | slot_counter[1] | slot_counter[0];
    
    // Carry lookahead logic
    assign carry_internal[0] = 1'b0; // Initial carry
    assign carry_internal[1] = generate_signal[0] | (propagate_signal[0] & carry_internal[0]);
    assign carry_internal[2] = generate_signal[1] | (propagate_signal[1] & carry_internal[1]);
    assign carry_out = generate_signal[2] | (propagate_signal[2] & carry_internal[2]);
    
    // Next value calculation for slot_counter
    assign slot_counter_next[0] = slot_counter[0] ^ 1'b1;
    assign slot_counter_next[1] = slot_counter[1] ^ carry_internal[1];
    assign slot_counter_next[2] = slot_counter[2] ^ carry_internal[2];
    
    // Next value calculation for current_slot
    assign current_slot_next[0] = current_slot[0] ^ 1'b1;
    assign current_slot_next[1] = current_slot[1] ^ (current_slot[0] & carry_out);
    assign current_slot_next[2] = current_slot[2] ^ (current_slot[1] & current_slot[0] & carry_out);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            slot_counter <= 0;
            current_slot <= 0;
            active_irq <= 0;
            active_slot <= 0;
            slot_width <= timeslot_width[0];
        end else begin
            // Update slot counter using carry-lookahead adder
            if (slot_counter < slot_width)
                slot_counter <= slot_counter_next;
            else begin
                slot_counter <= 0;
                current_slot <= current_slot_next % TIMESLOTS;
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