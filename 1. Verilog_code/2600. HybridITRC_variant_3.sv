//SystemVerilog
module HybridITRC (
    input wire clk, rst_n,
    input wire [3:0] async_irq,
    input wire [3:0] sync_irq,
    input wire [3:0] irq_priority,
    output wire async_valid,
    output reg [1:0] async_id,
    output reg sync_valid,
    output reg [1:0] sync_id,
    output reg irq_valid,
    input wire async_ready,
    input wire sync_ready,
    input wire irq_ready
);

    // Asynchronous part (combinational)
    wire [3:0] effective_async = async_irq & irq_priority;
    assign async_valid = |effective_async;

    // Priority encoder for async_id
    always @(*) begin
        async_id = (effective_async[3] ? 3 :
                    effective_async[2] ? 2 :
                    effective_async[1] ? 1 : 0);
    end

    // Synchronous part
    reg async_active_reg;
    reg sync_active_reg;
    reg irq_out_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_valid <= 0;
            sync_id <= 0;
            irq_valid <= 0;
            async_active_reg <= 0;
            sync_active_reg <= 0;
            irq_out_reg <= 0;
        end else begin
            if (async_ready) begin
                async_active_reg <= async_valid;
            end

            if (sync_ready) begin
                sync_valid <= |sync_irq;
                sync_id <= (sync_irq[3] ? 3 :
                           sync_irq[2] ? 2 :
                           sync_irq[1] ? 1 : 0);
                sync_active_reg <= |sync_irq;
            end

            if (irq_ready) begin
                irq_valid <= (async_active_reg && (irq_priority[async_id] >= irq_priority[sync_id] || !sync_active_reg)) || sync_active_reg;
                irq_out_reg <= (async_active_reg && (irq_priority[async_id] >= irq_priority[sync_id] || !sync_active_reg)) || sync_active_reg;
            end
        end
    end
endmodule