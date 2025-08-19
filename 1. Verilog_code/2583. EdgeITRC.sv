module EdgeITRC (
    input wire clock, resetn,
    input wire [7:0] irq_sources,
    input wire irq_ack,
    output reg irq_out,
    output reg [2:0] irq_num
);
    reg [7:0] irq_prev, irq_edge, irq_pending;
    
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            irq_prev <= 8'h0; irq_edge <= 8'h0; 
            irq_pending <= 8'h0; irq_out <= 1'b0;
        end else begin
            irq_prev <= irq_sources;
            irq_edge <= irq_sources & ~irq_prev; // Rising edge detection
            irq_pending <= (irq_pending | irq_edge) & 
                          ~(irq_ack ? (8'h01 << irq_num) : 8'h0);
            irq_out <= |irq_pending;
            
            // Priority encoder for pending interrupts
            for (int i = 7; i >= 0; i--)
                if (irq_pending[i]) irq_num <= i;
        end
    end
endmodule