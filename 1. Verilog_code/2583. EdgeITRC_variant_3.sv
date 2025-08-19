//SystemVerilog
module EdgeITRC (
    input wire clock, resetn,
    input wire [7:0] irq_sources,
    input wire irq_ack,
    output reg irq_out,
    output reg [2:0] irq_num
);
    // Sequential logic registers
    reg [7:0] irq_prev, irq_edge, irq_pending;
    
    // Combinational logic signals
    wire [7:0] irq_ack_mask;
    wire [2:0] next_irq_num;
    wire next_irq_out;
    
    // Combinational logic for acknowledgment mask
    assign irq_ack_mask = 8'h01 << irq_num;
    
    // Combinational logic for edge detection
    wire [7:0] irq_edge_comb;
    assign irq_edge_comb = irq_sources & ~irq_prev;
    
    // Combinational logic for pending logic
    wire [7:0] next_irq_pending;
    assign next_irq_pending = (irq_pending | irq_edge) & ~(irq_ack ? irq_ack_mask : 8'h0);
    
    // Combinational logic for priority encoder
    PriorityEncoder priority_encoder (
        .irq_pending(irq_pending),
        .current_irq_num(irq_num),
        .next_irq_num(next_irq_num)
    );
    
    // Combinational logic for OR reduction
    assign next_irq_out = (irq_pending[7:4] != 4'b0) | (irq_pending[3:0] != 4'b0);
    
    // Sequential logic
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            irq_prev <= 8'h0;
            irq_edge <= 8'h0;
            irq_pending <= 8'h0;
            irq_out <= 1'b0;
            irq_num <= 3'b0;
        end else begin
            irq_prev <= irq_sources;
            irq_edge <= irq_edge_comb;
            irq_pending <= next_irq_pending;
            irq_num <= next_irq_num;
            irq_out <= next_irq_out;
        end
    end
endmodule

// Combinational logic module for priority encoder
module PriorityEncoder (
    input wire [7:0] irq_pending,
    input wire [2:0] current_irq_num,
    output reg [2:0] next_irq_num
);
    always @(*) begin
        if (irq_pending[7:4] != 4'b0) begin
            if (irq_pending[7:6] != 2'b0) begin
                next_irq_num = irq_pending[7] ? 3'd7 : 3'd6;
            end else begin
                next_irq_num = irq_pending[5] ? 3'd5 : 3'd4;
            end
        end else if (irq_pending[3:0] != 4'b0) begin
            if (irq_pending[3:2] != 2'b0) begin
                next_irq_num = irq_pending[3] ? 3'd3 : 3'd2;
            end else begin
                next_irq_num = irq_pending[1] ? 3'd1 : 3'd0;
            end
        end else begin
            next_irq_num = current_irq_num; // Maintain current value if no pending
        end
    end
endmodule