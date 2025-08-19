//SystemVerilog
module RoundRobinITRC #(parameter WIDTH=8) (
    input wire clock, reset,
    input wire [WIDTH-1:0] interrupts,
    output reg service_req,
    output reg [2:0] service_id
);

    // Pipeline stage 1: Position tracking and interrupt shifting
    reg [2:0] current_position;
    wire [WIDTH-1:0] shifted_interrupts;
    reg [WIDTH-1:0] shifted_interrupts_reg;
    
    // Pipeline stage 2: Priority encoding
    wire [2:0] found_id;
    reg [2:0] found_id_reg;
    
    // Pipeline stage 3: Next position calculation and output generation
    wire [2:0] next_position;
    reg [2:0] next_position_reg;
    reg has_interrupt_reg;

    // Stage 1: Position tracking and interrupt shifting
    always @(posedge clock) begin
        if (reset) begin
            current_position <= 0;
            shifted_interrupts_reg <= 0;
        end else begin
            current_position <= next_position_reg;
            shifted_interrupts_reg <= shifted_interrupts;
        end
    end

    // Combinational logic for interrupt shifting
    assign shifted_interrupts = interrupts << current_position | interrupts >> (WIDTH - current_position);

    // Stage 2: Priority encoding
    always @(posedge clock) begin
        if (reset) begin
            found_id_reg <= 0;
        end else begin
            found_id_reg <= found_id;
        end
    end

    // Priority encoder for next interrupt
    assign found_id = shifted_interrupts_reg[0] ? 0 :
                     shifted_interrupts_reg[1] ? 1 :
                     shifted_interrupts_reg[2] ? 2 :
                     shifted_interrupts_reg[3] ? 3 :
                     shifted_interrupts_reg[4] ? 4 :
                     shifted_interrupts_reg[5] ? 5 :
                     shifted_interrupts_reg[6] ? 6 :
                     shifted_interrupts_reg[7] ? 7 : 0;

    // Stage 3: Next position calculation and output generation
    always @(posedge clock) begin
        if (reset) begin
            next_position_reg <= 0;
            service_req <= 0;
            service_id <= 0;
            has_interrupt_reg <= 0;
        end else begin
            next_position_reg <= next_position;
            service_req <= has_interrupt_reg;
            service_id <= found_id_reg;
            has_interrupt_reg <= |interrupts;
        end
    end

    // Calculate next position
    assign next_position = (found_id_reg + current_position) % WIDTH;

endmodule