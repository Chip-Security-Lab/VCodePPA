//SystemVerilog
module AutoClearIVMU (
    input clk, rstn,
    input [7:0] irq_in,
    input int_ack, // Changed from service_done for Req-Ack protocol
    output reg [31:0] int_vector,
    output reg int_req // Changed from int_active for Req-Ack protocol
);
    reg [31:0] vector_lut [0:7];
    reg [7:0] active_irqs, pending_irqs;
    reg [2:0] current_irq;

    // Function implementing 32-bit ripple-carry addition with cin=0
    // This function is used to calculate constant values in the initial block.
    function [31:0] ripple_carry_add_func (input [31:0] a, input [31:0] b);
        reg [31:0] sum;
        reg [32:0] carry;
        begin
            carry[0] = 1'b0; // Assume cin is 0 for this specific use case

            for (int i = 0; i < 32; i++) begin
                sum[i] = a[i] ^ b[i] ^ carry[i];
                carry[i+1] = (a[i] & b[i]) | (carry[i] & (a[i] ^ b[i]));
            end
        end
        return sum;
    endfunction

    initial begin
        // Use the ripple_carry_add_func for the vector calculations
        // The multiplication (i * 16) is still performed using standard operators
        vector_lut[0] = ripple_carry_add_func(32'hF000_0000, (0 * 16));
        vector_lut[1] = ripple_carry_add_func(32'hF000_0000, (1 * 16));
        vector_lut[2] = ripple_carry_add_func(32'hF000_0000, (2 * 16));
        vector_lut[3] = ripple_carry_add_func(32'hF000_0000, (3 * 16));
        vector_lut[4] = ripple_carry_add_func(32'hF000_0000, (4 * 16));
        vector_lut[5] = ripple_carry_add_func(32'hF000_0000, (5 * 16));
        vector_lut[6] = ripple_carry_add_func(32'hF000_0000, (6 * 16));
        vector_lut[7] = ripple_carry_add_func(32'hF000_0000, (7 * 16));
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            active_irqs <= 8'h0;
            pending_irqs <= 8'h0;
            int_req <= 1'b0; // Reset int_req
            current_irq <= 3'b0;
            int_vector <= 32'h0;
        end else begin
            // Always update pending_irqs with new requests
            pending_irqs <= pending_irqs | irq_in;

            // Req-Ack handshake logic
            // If request is active and acknowledged by receiver
            if (int_req && int_ack) begin
                // Clear the active IRQ bit associated with the completed request
                active_irqs[current_irq] <= 1'b0;
                // Deassert the request signal
                int_req <= 1'b0;
                // Clear the vector data after handshake completion
                int_vector <= 32'h0;
            end
            // If no request is currently active and there are pending IRQs
            else if (!int_req && |pending_irqs) begin
                // Assert the request signal
                int_req <= 1'b1;

                // Priority encode the highest pending IRQ (from 7 down to 0)
                if (pending_irqs[7]) begin
                    current_irq <= 7;
                    int_vector <= vector_lut[7];
                    active_irqs[7] <= 1'b1;
                    pending_irqs[7] <= 1'b0;
                end else if (pending_irqs[6]) begin
                    current_irq <= 6;
                    int_vector <= vector_lut[6];
                    active_irqs[6] <= 1'b1;
                    pending_irqs[6] <= 1'b0;
                end else if (pending_irqs[5]) begin
                    current_irq <= 5;
                    int_vector <= vector_lut[5];
                    active_irqs[5] <= 1'b1;
                    pending_irqs[5] <= 1'b0;
                end else if (pending_irqs[4]) begin
                    current_irq <= 4;
                    int_vector <= vector_lut[4];
                    active_irqs[4] <= 1'b1;
                    pending_irqs[4] <= 1'b0;
                end else if (pending_irqs[3]) begin
                    current_irq <= 3;
                    int_vector <= vector_lut[3];
                    active_irqs[3] <= 1'b1;
                    pending_irqs[3] <= 1'b0;
                end else if (pending_irqs[2]) begin
                    current_irq <= 2;
                    int_vector <= vector_lut[2];
                    active_irqs[2] <= 1'b1;
                    pending_irqs[2] <= 1'b0;
                end else if (pending_irqs[1]) begin
                    current_irq <= 1;
                    int_vector <= vector_lut[1];
                    active_irqs[1] <= 1'b1;
                    pending_irqs[1] <= 1'b0;
                end else if (pending_irqs[0]) begin
                    current_irq <= 0;
                    int_vector <= vector_lut[0];
                    active_irqs[0] <= 1'b1;
                    pending_irqs[0] <= 1'b0;
                end
            end
            // Else (int_req is high but int_ack is low, or !int_req and !|pending_irqs),
            // the state (int_req, int_vector, current_irq, active_irqs) is maintained.
        end
    end
endmodule