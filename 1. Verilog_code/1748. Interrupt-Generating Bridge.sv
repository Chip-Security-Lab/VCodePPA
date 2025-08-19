module irq_bridge #(parameter DWIDTH=32, AWIDTH=8) (
    input clk, rst_n,
    input [AWIDTH-1:0] addr,
    input [DWIDTH-1:0] wdata,
    input wr_en, rd_en,
    output reg [DWIDTH-1:0] rdata,
    output reg ready,
    output reg irq
);
    reg [DWIDTH-1:0] registers [0:2**AWIDTH-1];
    reg [7:0] irq_status, irq_enable;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            ready <= 1;
            irq <= 0;
            irq_status <= 0;
            irq_enable <= 0;
        end else begin
            // Handle register access
            if (wr_en && ready) begin
                registers[addr] <= wdata;
                ready <= 0;
                
                // Special registers
                if (addr == 8'hFE) irq_enable <= wdata[7:0];
                else if (addr == 8'hFF) irq_status <= irq_status & ~wdata[7:0]; // Clear on write
                
                // Generate interrupt on specific addresses
                if (addr >= 8'h80 && addr < 8'hA0) begin
                    irq_status[0] <= 1;
                end
            end else if (rd_en && ready) begin
                if (addr == 8'hFE) rdata <= {24'b0, irq_enable};
                else if (addr == 8'hFF) rdata <= {24'b0, irq_status};
                else rdata <= registers[addr];
                ready <= 0;
            end else if (!ready) begin
                ready <= 1;
            end
            
            // Interrupt generation
            irq <= |(irq_status & irq_enable);
        end
    end
endmodule