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
    
    // Pipeline registers
    reg [2:0] next_slot;
    reg [2:0] next_width;
    reg irq_detected;
    reg [1:0] detected_slot;
    
    // Kogge-Stone adder signals
    wire [2:0] kogge_sum;
    wire [2:0] kogge_carry;
    wire [2:0] kogge_propagate;
    wire [2:0] kogge_generate;
    
    // Kogge-Stone adder implementation
    // Generate and propagate signals
    assign kogge_propagate[0] = current_slot[0] ^ 1'b1;
    assign kogge_generate[0] = current_slot[0] & 1'b1;
    
    assign kogge_propagate[1] = current_slot[1] ^ 1'b0;
    assign kogge_generate[1] = current_slot[1] & 1'b0;
    
    assign kogge_propagate[2] = current_slot[2] ^ 1'b0;
    assign kogge_generate[2] = current_slot[2] & 1'b0;
    
    // First level of Kogge-Stone
    wire [2:0] level1_propagate;
    wire [2:0] level1_generate;
    
    assign level1_propagate[0] = kogge_propagate[0];
    assign level1_generate[0] = kogge_generate[0];
    
    assign level1_propagate[1] = kogge_propagate[1] & kogge_propagate[0];
    assign level1_generate[1] = kogge_generate[1] | (kogge_propagate[1] & kogge_generate[0]);
    
    assign level1_propagate[2] = kogge_propagate[2] & kogge_propagate[1];
    assign level1_generate[2] = kogge_generate[2] | (kogge_propagate[2] & kogge_generate[1]);
    
    // Second level of Kogge-Stone
    wire [2:0] level2_propagate;
    wire [2:0] level2_generate;
    
    assign level2_propagate[0] = level1_propagate[0];
    assign level2_generate[0] = level1_generate[0];
    
    assign level2_propagate[1] = level1_propagate[1];
    assign level2_generate[1] = level1_generate[1];
    
    assign level2_propagate[2] = level1_propagate[2] & level1_propagate[0];
    assign level2_generate[2] = level1_generate[2] | (level1_propagate[2] & level1_generate[0]);
    
    // Final carry computation
    assign kogge_carry[0] = level2_generate[0];
    assign kogge_carry[1] = level2_generate[1];
    assign kogge_carry[2] = level2_generate[2];
    
    // Sum computation
    assign kogge_sum[0] = kogge_propagate[0] ^ kogge_carry[0];
    assign kogge_sum[1] = kogge_propagate[1] ^ kogge_carry[1];
    assign kogge_sum[2] = kogge_propagate[2] ^ kogge_carry[2];
    
    // Combinational logic for next state
    always @(*) begin
        if (slot_counter < slot_width) begin
            next_slot = current_slot;
            next_width = slot_width;
        end else begin
            next_slot = kogge_sum % TIMESLOTS;
            next_width = timeslot_width[kogge_sum % TIMESLOTS];
        end
        
        irq_detected = irq_sources[current_slot];
        detected_slot = current_slot;
    end
    
    // Sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            slot_counter <= 0;
            current_slot <= 0;
            active_irq <= 0;
            active_slot <= 0;
            slot_width <= timeslot_width[0];
        end else begin
            // Update slot counter and state
            if (slot_counter < slot_width)
                slot_counter <= slot_counter + 1;
            else
                slot_counter <= 0;
                
            current_slot <= next_slot;
            slot_width <= next_width;
            
            // Update outputs
            active_irq <= irq_detected;
            active_slot <= detected_slot;
        end
    end

endmodule