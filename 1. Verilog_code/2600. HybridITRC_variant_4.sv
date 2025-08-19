//SystemVerilog
// Priority Encoder Module
module PriorityEncoder (
    input wire [3:0] irq_in,
    output reg [1:0] id_out
);
    always @(*) begin
        id_out = 0;
        if (irq_in[3]) id_out = 3;
        else if (irq_in[2]) id_out = 2;
        else if (irq_in[1]) id_out = 1;
        else if (irq_in[0]) id_out = 0;
    end
endmodule

// Buffer Module
module SignalBuffer (
    input wire clk,
    input wire rst_n,
    input wire [3:0] sync_irq_in,
    input wire [3:0] irq_priority_in,
    input wire [3:0] effective_async_in,
    input wire [1:0] async_id_in,
    output reg [3:0] sync_irq_out,
    output reg [3:0] irq_priority_out,
    output reg [3:0] effective_async_out,
    output reg [1:0] async_id_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_irq_out <= 4'b0;
            irq_priority_out <= 4'b0;
            effective_async_out <= 4'b0;
            async_id_out <= 2'b0;
        end else begin
            sync_irq_out <= sync_irq_in;
            irq_priority_out <= irq_priority_in;
            effective_async_out <= effective_async_in;
            async_id_out <= async_id_in;
        end
    end
endmodule

// IRQ Controller Module
module IRQController (
    input wire clk,
    input wire rst_n,
    input wire [3:0] sync_irq_buf,
    input wire [3:0] irq_priority_buf,
    input wire async_active,
    input wire [1:0] async_id_buf,
    output reg sync_active,
    output reg [1:0] sync_id,
    output reg irq_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_active <= 0;
            sync_id <= 0;
            irq_out <= 0;
        end else begin
            sync_active <= |sync_irq_buf;
            
            if (sync_irq_buf[3]) sync_id <= 3;
            else if (sync_irq_buf[2]) sync_id <= 2;
            else if (sync_irq_buf[1]) sync_id <= 1;
            else if (sync_irq_buf[0]) sync_id <= 0;
            
            if (async_active && (irq_priority_buf[async_id_buf] >= irq_priority_buf[sync_id] || !sync_active)) begin
                irq_out <= 1;
            end else if (sync_active) begin
                irq_out <= 1;
            end else begin
                irq_out <= 0;
            end
        end
    end
endmodule

// Top Module
module HybridITRC (
    input wire clk,
    input wire rst_n,
    input wire [3:0] async_irq,
    input wire [3:0] sync_irq,
    input wire [3:0] irq_priority,
    output wire async_active,
    output wire [1:0] async_id,
    output wire sync_active,
    output wire [1:0] sync_id,
    output wire irq_out
);

    // Internal signals
    wire [3:0] effective_async;
    wire [3:0] sync_irq_buf;
    wire [3:0] irq_priority_buf;
    wire [3:0] effective_async_buf;
    wire [1:0] async_id_buf;
    
    // Combinational logic
    assign effective_async = async_irq & irq_priority_buf;
    assign async_active = |effective_async_buf;
    
    // Module instances
    PriorityEncoder async_encoder (
        .irq_in(effective_async_buf),
        .id_out(async_id)
    );
    
    SignalBuffer buffer (
        .clk(clk),
        .rst_n(rst_n),
        .sync_irq_in(sync_irq),
        .irq_priority_in(irq_priority),
        .effective_async_in(effective_async),
        .async_id_in(async_id),
        .sync_irq_out(sync_irq_buf),
        .irq_priority_out(irq_priority_buf),
        .effective_async_out(effective_async_buf),
        .async_id_out(async_id_buf)
    );
    
    IRQController controller (
        .clk(clk),
        .rst_n(rst_n),
        .sync_irq_buf(sync_irq_buf),
        .irq_priority_buf(irq_priority_buf),
        .async_active(async_active),
        .async_id_buf(async_id_buf),
        .sync_active(sync_active),
        .sync_id(sync_id),
        .irq_out(irq_out)
    );
endmodule