//SystemVerilog
module EdgeITRC (
    input wire clock, resetn,
    input wire [7:0] irq_sources,
    input wire irq_ack,
    output reg irq_out,
    output reg [2:0] irq_num
);
    reg [7:0] irq_prev, irq_edge, irq_pending;
    reg [7:0] irq_pending_buf1, irq_pending_buf2;
    reg irq_out_buf;
    wire [7:0] irq_ack_mask;
    
    assign irq_ack_mask = irq_ack ? (8'h01 << irq_num) : 8'h0;
    
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            irq_prev <= 8'h0; 
            irq_edge <= 8'h0; 
            irq_pending <= 8'h0;
            irq_pending_buf1 <= 8'h0;
            irq_pending_buf2 <= 8'h0;
            irq_out <= 1'b0;
            irq_out_buf <= 1'b0;
            irq_num <= 3'b0;
        end else begin
            irq_prev <= irq_sources;
            irq_edge <= irq_sources & ~irq_prev;
            
            irq_pending_buf1 <= (irq_pending | irq_edge) & ~irq_ack_mask;
            irq_pending_buf2 <= irq_pending_buf1;
            irq_pending <= irq_pending_buf2;
            
            irq_out_buf <= |irq_pending_buf2;
            irq_out <= irq_out_buf;
            
            casez (irq_pending_buf2)
                8'b1???????: irq_num <= 3'd7;
                8'b01??????: irq_num <= 3'd6;
                8'b001?????: irq_num <= 3'd5;
                8'b0001????: irq_num <= 3'd4;
                8'b00001???: irq_num <= 3'd3;
                8'b000001??: irq_num <= 3'd2;
                8'b0000001?: irq_num <= 3'd1;
                8'b00000001: irq_num <= 3'd0;
                default: irq_num <= irq_num;
            endcase
        end
    end
endmodule