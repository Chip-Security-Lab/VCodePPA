//SystemVerilog
module HybridITRC (
    input wire clk, rst_n,
    input wire [3:0] async_irq,
    input wire [3:0] sync_irq,
    input wire [3:0] irq_priority,
    output wire async_active,
    output reg [1:0] async_id,
    output reg sync_active,
    output reg [1:0] sync_id,
    output reg irq_out
);

    // Asynchronous part (combinational)
    wire [3:0] effective_async = async_irq & irq_priority;
    assign async_active = |effective_async;
    
    // Optimized priority encoder for async_id using casez
    always @(*) begin
        casez (effective_async)
            4'b1???: async_id = 2'd3;
            4'b01??: async_id = 2'd2;
            4'b001?: async_id = 2'd1;
            4'b0001: async_id = 2'd0;
            default: async_id = 2'd0;
        endcase
    end
    
    // Synchronous part
    reg [1:0] sync_id_next;
    reg irq_out_next;
    
    // Optimized priority encoder for sync_id using casez
    always @(*) begin
        casez (sync_irq)
            4'b1???: sync_id_next = 2'd3;
            4'b01??: sync_id_next = 2'd2;
            4'b001?: sync_id_next = 2'd1;
            4'b0001: sync_id_next = 2'd0;
            default: sync_id_next = 2'd0;
        endcase
    end
    
    // Optimized output determination
    always @(*) begin
        irq_out_next = (async_active && (irq_priority[async_id] >= irq_priority[sync_id_next] || !sync_active)) || 
                      (sync_active);
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_active <= 0;
            sync_id <= 0;
            irq_out <= 0;
        end else begin
            sync_active <= |sync_irq;
            sync_id <= sync_id_next;
            irq_out <= irq_out_next;
        end
    end
endmodule