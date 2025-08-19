//SystemVerilog
module rr_async_icmu (
    input rst,
    input [7:0] interrupt_in,
    input ctx_save_done,
    output reg [7:0] int_grant,
    output reg [2:0] int_vector,
    output reg context_save_req
);
    reg [2:0] last_served;
    reg [7:0] masked_ints;

    // LUT for mask generation (replaces i > last comparison)
    reg [7:0] mask_lut [0:7];

    initial begin
        mask_lut[0] = 8'b11111110; // i > 0
        mask_lut[1] = 8'b11111100; // i > 1
        mask_lut[2] = 8'b11111000; // i > 2
        mask_lut[3] = 8'b11110000; // i > 3
        mask_lut[4] = 8'b11100000; // i > 4
        mask_lut[5] = 8'b11000000; // i > 5
        mask_lut[6] = 8'b10000000; // i > 6
        mask_lut[7] = 8'b00000000; // i > 7
    end

    // 重构组合逻辑
    always @(*) begin
        // Original code copies interrupt_in to masked_ints
        masked_ints = interrupt_in;
        // context_save_req is high if any interrupt is active
        context_save_req = |masked_ints;

        // Use calling function
        int_grant = select_next(masked_ints, last_served);
        int_vector = encode_vec(int_grant);
    end

    always @(posedge ctx_save_done or posedge rst) begin
        if (rst) last_served <= 3'b0;
        else last_served <= int_vector;
    end

    // Modified function implementation using LUT for mask
    function [7:0] select_next;
        input [7:0] ints;
        input [2:0] last;
        reg [7:0] mask;
        reg [7:0] high_priority_ints; // All interrupts > last
        reg [7:0] any_priority_ints;  // All interrupts

        begin
            // Generate mask using LUT based on last_served index
            mask = mask_lut[last]; // This is the LUT replacement for i > last logic

            // Calculate high_result (all interrupts > last) using bitwise AND with the mask
            high_priority_ints = ints & mask;

            // Calculate any_result (all interrupts) - simply the input interrupts
            any_priority_ints = ints;

            // Select result: if any interrupt > last is active, grant those; otherwise, grant any active interrupt
            if (|high_priority_ints)
                select_next = high_priority_ints;
            else
                select_next = any_priority_ints;
        end
    endfunction

    // Function to encode grant vector to index (priority encoder)
    function [2:0] encode_vec;
        input [7:0] grant;
        begin
            // Casez prioritizes from MSB to LSB
            casez(grant)
                8'b1???????: encode_vec = 3'd7;
                8'b01??????: encode_vec = 3'd6;
                8'b001?????: encode_vec = 3'd5;
                8'b0001????: encode_vec = 3'd4;
                8'b00001???: encode_vec = 3'd3;
                8'b000001??: encode_vec = 3'd2;
                8'b0000001?: encode_vec = 3'd1;
                8'b00000001: encode_vec = 3'd0;
                default: encode_vec = 3'd0; // Should not be reached if |grant is true
            endcase
        end
    endfunction

    // Function to find the first set bit index (lowest priority index) - unused in main logic
    // Keeping this function as-is to match the original code structure.
    function [2:0] find_first;
        input [7:0] val;
        begin
            casez(val)
                8'b???????1: find_first = 3'd0; // Finds index of LSB
                8'b??????10: find_first = 3'd1;
                8'b?????100: find_first = 3'd2;
                8'b????1000: find_first = 3'd3;
                8'b???10000: find_first = 3'd4;
                8'b??100000: find_first = 3'd5;
                8'b?1000000: find_first = 3'd6;
                8'b10000000: find_first = 3'd7; // Finds index of MSB if others are low
                default: find_first = 3'd0;
            endcase
        end
    endfunction

endmodule