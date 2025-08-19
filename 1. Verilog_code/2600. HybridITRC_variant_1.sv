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

    // Registered signals
    reg [3:0] async_irq_reg;
    reg [3:0] sync_irq_reg;
    reg [3:0] irq_priority_reg;
    reg [3:0] effective_async_reg;
    reg async_active_reg;
    reg [1:0] async_id_reg;
    reg sync_active_reg;
    reg [1:0] sync_id_reg;
    reg irq_out_reg;
    reg [3:0] effective_async_reg2;
    reg async_active_reg2;
    reg [1:0] async_id_reg2;

    // Register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            async_irq_reg <= 0;
            sync_irq_reg <= 0;
            irq_priority_reg <= 0;
            effective_async_reg <= 0;
            async_active_reg <= 0;
            async_id_reg <= 0;
            effective_async_reg2 <= 0;
            async_active_reg2 <= 0;
            async_id_reg2 <= 0;
        end else begin
            async_irq_reg <= async_irq;
            sync_irq_reg <= sync_irq;
            irq_priority_reg <= irq_priority;
            effective_async_reg <= async_irq_reg & irq_priority_reg;
            async_active_reg <= |effective_async_reg;
            
            // Priority encoder for async_id
            if (effective_async_reg[3]) async_id_reg <= 3;
            else if (effective_async_reg[2]) async_id_reg <= 2;
            else if (effective_async_reg[1]) async_id_reg <= 1;
            else if (effective_async_reg[0]) async_id_reg <= 0;
            
            effective_async_reg2 <= effective_async_reg;
            async_active_reg2 <= async_active_reg;
            async_id_reg2 <= async_id_reg;
        end
    end

    // Asynchronous part (combinational)
    assign async_active = async_active_reg2;
    assign async_id = async_id_reg2;

    // Synchronous part
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_active <= 0;
            sync_id <= 0;
            irq_out <= 0;
        end else begin
            sync_active <= |sync_irq_reg;
            
            // Priority encoder for sync_id
            if (sync_irq_reg[3]) sync_id <= 3;
            else if (sync_irq_reg[2]) sync_id <= 2;
            else if (sync_irq_reg[1]) sync_id <= 1;
            else if (sync_irq_reg[0]) sync_id <= 0;
            
            // Final output determination based on priority
            if (async_active_reg2 && (irq_priority_reg[async_id_reg2] >= irq_priority_reg[sync_id] || !sync_active)) begin
                irq_out <= 1;
            end else if (sync_active) begin
                irq_out <= 1;
            end else begin
                irq_out <= 0;
            end
        end
    end

endmodule