module AutoClearIVMU (
    input clk, rstn,
    input [7:0] irq_in,
    input service_done,
    output reg [31:0] int_vector,
    output reg int_active
);
    reg [31:0] vector_lut [0:7];
    reg [7:0] active_irqs, pending_irqs;
    reg [2:0] current_irq;
    integer i;
    
    initial for (i = 0; i < 8; i = i + 1)
        vector_lut[i] = 32'hF000_0000 + (i * 16);
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            active_irqs <= 8'h0;
            pending_irqs <= 8'h0;
            int_active <= 1'b0;
        end else begin
            pending_irqs <= pending_irqs | irq_in;
            
            if (service_done) begin
                active_irqs[current_irq] <= 1'b0;
                int_active <= 1'b0;
            end else if (!int_active && |pending_irqs) begin
                int_active <= 1'b1;
                for (i = 7; i >= 0; i = i - 1) begin
                    if (pending_irqs[i]) begin
                        current_irq <= i[2:0];
                        int_vector <= vector_lut[i[2:0]];
                        active_irqs[i] <= 1'b1;
                        pending_irqs[i] <= 1'b0;
                    end
                end
            end
        end
    end
endmodule