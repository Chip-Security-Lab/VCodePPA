module HybridITRC (
    input wire clk, rst_n,
    input wire [3:0] async_irq,
    input wire [3:0] sync_irq,
    input wire [3:0] irq_priority, // Higher value = higher priority
    output wire async_active,
    output reg [1:0] async_id,
    output reg sync_active,
    output reg [1:0] sync_id,
    output reg irq_out
);
    // Asynchronous part (combinational)
    wire [3:0] effective_async = async_irq & irq_priority;
    assign async_active = |effective_async;
    
    // Priority encoder for async_id
    always @(*) begin
        async_id = 0;
        if (effective_async[3]) async_id = 3;
        else if (effective_async[2]) async_id = 2;
        else if (effective_async[1]) async_id = 1;
        else if (effective_async[0]) async_id = 0;
    end
    
    // Synchronous part
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_active <= 0;
            sync_id <= 0;
            irq_out <= 0;
        end else begin
            sync_active <= |sync_irq;
            
            // Priority encoder for sync_id
            if (sync_irq[3]) sync_id <= 3;
            else if (sync_irq[2]) sync_id <= 2;
            else if (sync_irq[1]) sync_id <= 1;
            else if (sync_irq[0]) sync_id <= 0;
            
            // Final output determination based on priority
            if (async_active && (irq_priority[async_id] >= irq_priority[sync_id] || !sync_active)) begin
                irq_out <= 1;
            end else if (sync_active) begin
                irq_out <= 1;
            end else begin
                irq_out <= 0;
            end
        end
    end
endmodule