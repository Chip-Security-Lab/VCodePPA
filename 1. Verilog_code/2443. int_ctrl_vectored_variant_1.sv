//SystemVerilog
// SystemVerilog
module int_ctrl_vectored #(
    parameter VEC_W = 16
)(
    input                   clk,      // System clock
    input                   rst,      // Synchronous reset
    input      [VEC_W-1:0] int_in,   // Interrupt input vector
    input      [VEC_W-1:0] mask_reg, // Interrupt mask register
    output reg [VEC_W-1:0] int_out   // Processed interrupt output
);

    // Stage 1: Interrupt detection and latching
    reg [VEC_W-1:0] int_detected;
    
    // Stage 2: Interrupt masking
    reg [VEC_W-1:0] int_masked;
    
    // Stage 3: Pending interrupt register with two's complement subtraction
    reg [VEC_W-1:0] pending_reg;
    reg [VEC_W-1:0] clear_mask;
    reg [VEC_W-1:0] subtrahend;      // Two's complement of clear_mask
    reg [VEC_W-1:0] sub_result;      // Result of subtraction
    reg             carry;           // Carry bit for two's complement

    // Calculate two's complement of clear_mask for subtraction
    always @(*) begin
        // Two's complement: invert bits and add 1
        subtrahend = (~clear_mask) + 1'b1;
        
        // Calculate subtraction using two's complement addition
        {carry, sub_result} = {1'b0, pending_reg} + {1'b0, subtrahend};
    end

    // Pipeline Stage 1: Detect and latch new interrupts
    always @(posedge clk) begin
        if (rst) begin
            int_detected <= {VEC_W{1'b0}};
        end else begin
            int_detected <= int_in;
        end
    end

    // Pipeline Stage 2: Apply interrupt mask
    always @(posedge clk) begin
        if (rst) begin
            int_masked <= {VEC_W{1'b0}};
            clear_mask <= {VEC_W{1'b0}};
        end else begin
            int_masked <= int_detected & mask_reg;
            clear_mask <= ~int_masked & pending_reg; // Clear mask for processed interrupts
        end
    end

    // Pipeline Stage 3: Update pending register using two's complement subtraction
    always @(posedge clk) begin
        if (rst) begin
            pending_reg <= {VEC_W{1'b0}};
        end else begin
            for (int i = 0; i < VEC_W; i = i + 1) begin
                if (int_masked[i]) begin
                    pending_reg[i] <= 1'b1; // Set interrupt pending
                end else if (clear_mask[i]) begin
                    pending_reg[i] <= sub_result[i]; // Apply result of two's complement subtraction
                end
            end
        end
    end

    // Pipeline Stage 4: Output register
    always @(posedge clk) begin
        if (rst) begin
            int_out <= {VEC_W{1'b0}};
        end else begin
            int_out <= pending_reg;
        end
    end

endmodule