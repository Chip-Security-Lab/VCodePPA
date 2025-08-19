//SystemVerilog
module AutoClearIVMU (
    input clk, rstn,
    input [7:0] irq_in,
    input service_done,
    output reg [31:0] int_vector,
    output reg int_active
);

    reg [31:0] vector_lut [0:7];
    reg [7:0] active_irqs;
    reg [7:0] pending_irqs; // Made reg as it's updated with NBAs
    reg [2:0] current_irq;

    integer i; // Keep integer for initial block

    initial begin
        for (i = 0; i < 8; i = i + 1) begin
            vector_lut[i] = 32'hF000_0000 + (i * 16);
        end
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            active_irqs <= 8'h0;
            pending_irqs <= 8'h0;
            int_active <= 1'b0;
            current_irq <= 3'd0; // Initialize current_irq
            int_vector <= 32'h0; // Initialize int_vector
        end else begin
            // Accumulate incoming interrupts
            pending_irqs <= pending_irqs | irq_in;

            if (service_done) begin
                // Clear the currently active interrupt when service is done
                active_irqs[current_irq] <= 1'b0;
                int_active <= 1'b0;
            end else if (!int_active && |pending_irqs) begin
                // If no interrupt is active and there are pending interrupts, activate the highest priority one
                int_active <= 1'b1;

                // Optimized priority encoder logic to find the highest priority pending IRQ
                // Converted if-else if to case statement
                case (pending_irqs)
                    8'b1???????: begin // Priority 7
                        current_irq <= 3'd7;
                        int_vector <= vector_lut[7];
                        active_irqs[7] <= 1'b1;
                        pending_irqs[7] <= 1'b0; // Clear the pending flag for the selected IRQ
                    end
                    8'b01??????: begin // Priority 6
                        current_irq <= 3'd6;
                        int_vector <= vector_lut[6];
                        active_irqs[6] <= 1'b1;
                        pending_irqs[6] <= 1'b0;
                    end
                    8'b001?????: begin // Priority 5
                        current_irq <= 3'd5;
                        int_vector <= vector_lut[5];
                        active_irqs[5] <= 1'b1;
                        pending_irqs[5] <= 1'b0;
                    end
                    8'b0001????: begin // Priority 4
                        current_irq <= 3'd4;
                        int_vector <= vector_lut[4];
                        active_irqs[4] <= 1'b1;
                        pending_irqs[4] <= 1'b0;
                    end
                    8'b00001???: begin // Priority 3
                        current_irq <= 3'd3;
                        int_vector <= vector_lut[3];
                        active_irqs[3] <= 1'b1;
                        pending_irqs[3] <= 1'b0;
                    end
                    8'b000001??: begin // Priority 2
                        current_irq <= 3'd2;
                        int_vector <= vector_lut[2];
                        active_irqs[2] <= 1'b1;
                        pending_irqs[2] <= 1'b0;
                    end
                    8'b0000001?: begin // Priority 1
                        current_irq <= 3'd1;
                        int_vector <= vector_lut[1];
                        active_irqs[1] <= 1'b1;
                        pending_irqs[1] <= 1'b0;
                    end
                    8'b00000001: begin // Priority 0
                        current_irq <= 3'd0;
                        int_vector <= vector_lut[0];
                        active_irqs[0] <= 1'b1;
                        pending_irqs[0] <= 1'b0;
                    end
                    // The outer condition `|pending_irqs` ensures that at least one bit is set,
                    // so one of the branches above will be taken. No default needed.
                endcase
            end
        end
    end

endmodule