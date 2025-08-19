//SystemVerilog
module multilevel_icmu (
    input clock, resetn,
    input [7:0] interrupts,
    input [15:0] priority_level_flat,
    input ack_in, // Converted from Valid-Ready ack_done
    output reg [2:0] int_number,
    output reg [31:0] saved_context,
    output reg req_out, // New output for Request signal
    input [31:0] current_context
);
    wire [1:0] priority_level [0:7]; // Internal array for priority levels
    reg [7:0] level0_mask, level1_mask, level2_mask, level3_mask; // Masks for each priority level
    reg [1:0] current_level; // Priority level of the currently handled interrupt
    reg handle_active; // Internal state flag indicating an interrupt is being handled (drives req_out)
    integer i; // Loop variable

    // From flattened array to individual priority levels
    genvar g;
    generate
        for (g = 0; g < 8; g = g + 1) begin: prio_level_map
            assign priority_level[g] = priority_level_flat[g*2+1:g*2];
        end
    endgenerate

    // Calculate masks based on priority levels
    always @(*) begin
        level0_mask = 0;
        level1_mask = 0;
        level2_mask = 0;
        level3_mask = 0;

        for (i = 0; i < 8; i = i + 1) begin
            case (priority_level[i])
                2'd0: level0_mask[i] = 1'b1;
                2'd1: level1_mask[i] = 1'b1;
                2'd2: level2_mask[i] = 1'b1;
                2'd3: level3_mask[i] = 1'b1;
            endcase
        end
    end

    // Sequential logic for state transitions and output updates (Req-Ack handshake)
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            // Reset state
            int_number <= 3'd0;
            handle_active <= 1'b0;
            current_level <= 2'd0;
            saved_context <= 32'd0;
            req_out <= 1'b0; // Deassert request on reset
        end else begin
            // Default: hold current state/outputs
            int_number <= int_number;
            handle_active <= handle_active;
            current_level <= current_level;
            saved_context <= saved_context;
            req_out <= req_out; // Hold request state

            // State transition: Idle -> Request
            // If no interrupt is being handled AND there are pending interrupts
            if (!handle_active && |interrupts) begin
                // Select the highest priority pending interrupt
                if (|(interrupts & level3_mask)) begin
                    int_number <= find_first_set(interrupts & level3_mask);
                    current_level <= 2'd3;
                end else if (|(interrupts & level2_mask)) begin
                    int_number <= find_first_set(interrupts & level2_mask);
                    current_level <= 2'd2;
                end else if (|(interrupts & level1_mask)) begin
                    int_number <= find_first_set(interrupts & level1_mask);
                    current_level <= 2'd1;
                end else begin // If any interrupt is pending, at least one must be level 0
                    int_number <= find_first_set(interrupts & level0_mask);
                    current_level <= 2'd0;
                end
                // Assert handle_active and req_out, save context
                handle_active <= 1'b1; // Go to handling state
                req_out <= 1'b1; // Assert Request signal
                saved_context <= current_context; // Save context at the time of selection
            end
            // State transition: Request -> Idle
            // If an interrupt is being handled AND the downstream acknowledges
            else if (handle_active && ack_in) begin // Use ack_in for acknowledgement
                // Deassert handle_active and req_out
                handle_active <= 1'b0; // Return to idle state
                req_out <= 1'b0; // Deassert Request signal
                // Data outputs (int_number, saved_context) will hold their value until the next request
            end
            // If handle_active is high but ack_in is low, stay in Request state (handle_active=1, req_out=1)
            // If handle_active is low and |interrupts is low, stay in Idle state (handle_active=0, req_out=0)
        end
    end

    // Function to find the index of the first set bit (LSB to MSB)
    function [2:0] find_first_set;
        input [7:0] bits;
        reg [2:0] result;
        begin
            casez(bits)
                8'b???????1: result = 3'd0;
                8'b??????10: result = 3'd1;
                8'b?????100: result = 3'd2;
                8'b????1000: result = 3'd3;
                8'b???10000: result = 3'd4;
                8'b??100000: result = 3'd5;
                8'b?1000000: result = 3'd6;
                8'b10000000: result = 3'd7;
                default: result = 3'd0; // Should ideally not be reached if |bits is true
            endcase
            find_first_set = result;
        end
    endfunction

endmodule