//SystemVerilog
module MemMappedIVMU (
    input wire clk,
    input wire rst_n,
    input wire [7:0] addr,
    input wire [31:0] wdata,
    // Valid-Ready Write Interface
    input wire wr_valid,
    output wire wr_ready,
    // Valid-Ready Read Interface
    input wire rd_valid,
    output wire rd_ready,
    output reg [31:0] rdata, // Read data
    input wire [15:0] irq_sources,
    output reg [31:0] irq_vector,
    output reg irq_valid
);

    reg [31:0] regs [0:17]; // 0-15: Vector table, 16: Mask, 17: Status
    wire [15:0] masked_irq;
    integer i;

    // The module is always ready to accept a request in the next cycle
    // as memory access is single-cycle and non-blocking.
    assign wr_ready = 1'b1;
    assign rd_ready = 1'b1;

    assign masked_irq = irq_sources & ~regs[16][15:0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 18; i = i + 1) regs[i] <= 0;
            irq_valid <= 0;
            irq_vector <= 0; // Reset irq_vector
            rdata <= 0; // Reset rdata
        end else begin
            // Write operation happens when wr_valid and wr_ready are high
            // Since wr_ready is always 1, this is effectively on wr_valid
            if (wr_valid && wr_ready) begin
                 // Only write to addresses 0-17 (regs size)
                 if (addr[4:0] < 18) begin
                    regs[addr[4:0]] <= wdata;
                 end
            end

            // Read operation happens when rd_valid and rd_ready are high
            // Since rd_ready is always 1, this is effectively on rd_valid
            // rdata is updated synchronously, available one cycle after request handshake
            if (rd_valid && rd_ready) begin
                 // Only read from addresses 0-17 (regs size)
                 if (addr[4:0] < 18) begin
                    rdata <= regs[addr[4:0]];
                 end else begin
                    rdata <= 32'h0; // Read from invalid address returns 0
                 end
            end
            // else rdata retains its previous value if no valid read request

            // IRQ logic remains the same
            irq_valid <= |masked_irq;
            // This loop assigns the highest priority vector (lowest index)
            // It should only update if irq_valid is high, but the original code
            // updates every cycle. Let's keep original behavior.
            irq_vector <= 0; // Default value
            for (i = 15; i >= 0; i = i - 1) begin
                if (masked_irq[i]) begin
                    irq_vector <= regs[i];
                end
            end

            // Status register update remains the same
            // regs[17] is the status register
            regs[17] <= {16'h0, masked_irq};
        end
    end

endmodule