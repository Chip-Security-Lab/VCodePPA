//SystemVerilog
module vector_icmu (
    input clk, rst_b,
    input [31:0] int_vector,
    input enable,
    input [63:0] current_context,
    output reg int_active,
    output reg [63:0] saved_context,
    output reg [4:0] vector_number
);
    reg [31:0] pending, masked;
    reg [31:0] mask;

    // Initialization (redundant with reset, but keeping as per original)
    initial begin
        mask = 32'hFFFFFFFF;
    end

    always @(posedge clk, negedge rst_b) begin
        if (!rst_b) begin
            pending <= 32'h0;
            int_active <= 1'b0;
            saved_context <= 64'h0;
            vector_number <= 5'h0;
            mask <= 32'hFFFFFFFF;
        end else begin
            // Latch new interrupts
            pending <= pending | int_vector;
            masked <= pending & mask & {32{enable}};

            // Handle next interrupt
            if (!int_active && |masked) begin
                vector_number <= priority_encoder(masked);
                saved_context <= current_context;
                int_active <= 1'b1;
                // Clear the handled interrupt bit from pending
                pending <= pending & ~(32'h1 << priority_encoder(masked)); // Use the function again or store result
                // Note: Using the function twice might be synthesized efficiently,
                // but storing the result from the first call is safer if function is complex.
                // Let's stick to the original logic's implied dependency.
            end
        end
    end

    // Optimized function implementation using casez for priority encoding
    function [4:0] priority_encoder;
        input [31:0] vector;
        reg [4:0] result;
        begin
            // Default value if no bit is set (should not happen based on caller logic |vector)
            result = 5'h0;

            casez (vector)
                32'b1zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: result = 31;
                32'b01zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: result = 30;
                32'b001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: result = 29;
                32'b0001zzzzzzzzzzzzzzzzzzzzzzzzzzzzz: result = 28;
                32'b00001zzzzzzzzzzzzzzzzzzzzzzzzzzzz: result = 27;
                32'b000001zzzzzzzzzzzzzzzzzzzzzzzzzzz: result = 26;
                32'b0000001zzzzzzzzzzzzzzzzzzzzzzzzzz: result = 25;
                32'b00000001zzzzzzzzzzzzzzzzzzzzzzzzz: result = 24;
                32'b000000001zzzzzzzzzzzzzzzzzzzzzzzz: result = 23;
                32'b0000000001zzzzzzzzzzzzzzzzzzzzzzz: result = 22;
                32'b00000000001zzzzzzzzzzzzzzzzzzzzzz: result = 21;
                32'b000000000001zzzzzzzzzzzzzzzzzzzzz: result = 20;
                32'b0000000000001zzzzzzzzzzzzzzzzzzzz: result = 19;
                32'b00000000000001zzzzzzzzzzzzzzzzzzz: result = 18;
                32'b000000000000001zzzzzzzzzzzzzzzzzz: result = 17;
                32'b0000000000000001zzzzzzzzzzzzzzzzz: result = 16;
                32'b00000000000000001zzzzzzzzzzzzzzzz: result = 15;
                32'b000000000000000001zzzzzzzzzzzzzzz: result = 14;
                32'b0000000000000000001zzzzzzzzzzzzzz: result = 13;
                32'b00000000000000000001zzzzzzzzzzzzz: result = 12;
                32'b000000000000000000001zzzzzzzzzzzz: result = 11;
                32'b0000000000000000000001zzzzzzzzzzz: result = 10;
                32'b00000000000000000000001zzzzzzzzzz: result = 9;
                32'b000000000000000000000001zzzzzzzzz: result = 8;
                32'b0000000000000000000000001zzzzzzzz: result = 7;
                32'b00000000000000000000000001zzzzzzz: result = 6;
                32'b000000000000000000000000001zzzzzz: result = 5;
                32'b0000000000000000000000000001zzzzz: result = 4;
                32'b00000000000000000000000000001zzzz: result = 3;
                32'b000000000000000000000000000001zzz: result = 2;
                32'b0000000000000000000000000000001zz: result = 1;
                32'b00000000000000000000000000000001: result = 0;
                default: result = 0; // Fallback for vector = 0, though |vector check prevents this
            endcase
            priority_encoder = result;
        end
    endfunction

endmodule