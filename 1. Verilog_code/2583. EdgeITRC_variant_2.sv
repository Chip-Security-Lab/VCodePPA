//SystemVerilog
module EdgeITRC (
    input wire clock, resetn,
    input wire [7:0] irq_sources,
    input wire irq_ack,
    output reg irq_out,
    output reg [2:0] irq_num
);
    reg [7:0] irq_prev, irq_edge, irq_pending;
    wire [7:0] irq_ack_mask;
    
    // Generate ack mask using shift operation
    assign irq_ack_mask = irq_ack ? (8'h01 << irq_num) : 8'h0;
    
    // Optimized edge detection and priority encoding
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            irq_prev <= 8'h0;
            irq_edge <= 8'h0;
            irq_pending <= 8'h0;
            irq_out <= 1'b0;
            irq_num <= 3'b0;
        end else begin
            irq_prev <= irq_sources;
            irq_edge <= irq_sources & ~irq_prev;
            
            // Optimized pending interrupt update
            irq_pending <= (irq_pending | irq_edge) & ~irq_ack_mask;
            irq_out <= |irq_pending;
            
            // Optimized priority encoder using case statement
            casex (irq_pending)
                8'b1xxxxxxx: irq_num <= 3'd7;
                8'b01xxxxxx: irq_num <= 3'd6;
                8'b001xxxxx: irq_num <= 3'd5;
                8'b0001xxxx: irq_num <= 3'd4;
                8'b00001xxx: irq_num <= 3'd3;
                8'b000001xx: irq_num <= 3'd2;
                8'b0000001x: irq_num <= 3'd1;
                8'b00000001: irq_num <= 3'd0;
                default: irq_num <= irq_num;
            endcase
        end
    end
endmodule