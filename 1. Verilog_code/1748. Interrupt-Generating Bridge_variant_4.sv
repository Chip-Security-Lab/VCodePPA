//SystemVerilog
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
    reg [DWIDTH-1:0] wdata_stage1, wdata_stage2;
    reg [AWIDTH-1:0] addr_stage1, addr_stage2;
    reg wr_en_stage1, wr_en_stage2, rd_en_stage1, rd_en_stage2;
    reg ready_stage1, ready_stage2;
    reg valid_stage1, valid_stage2;
    
    // Buffer registers for high fanout signals
    reg [7:0] irq_status_buf;
    reg [DWIDTH-1:0] wdata_stage2_buf;
    reg [AWIDTH-1:0] addr_stage2_buf;
    
    wire addr_in_special_range;
    wire addr_in_irq_range;
    wire [7:0] irq_status_next;
    wire [7:0] irq_enable_next;
    wire [DWIDTH-1:0] rdata_next;

    assign addr_in_special_range = (addr_stage2_buf == 8'hFE) || (addr_stage2_buf == 8'hFF);
    assign addr_in_irq_range = (addr_stage2_buf >= 8'h80) && (addr_stage2_buf < 8'hA0);
    assign irq_status_next = wr_en_stage2 ? 
        (addr_stage2_buf == 8'hFF ? irq_status_buf & ~wdata_stage2_buf[7:0] : 
        (addr_in_irq_range ? {irq_status_buf[7:1], 1'b1} : irq_status_buf)) : irq_status_buf;
    assign irq_enable_next = wr_en_stage2 && (addr_stage2_buf == 8'hFE) ? wdata_stage2_buf[7:0] : irq_enable;
    assign rdata_next = rd_en_stage2 ? 
        (addr_stage2_buf == 8'hFE ? {24'b0, irq_enable} : 
        (addr_stage2_buf == 8'hFF ? {24'b0, irq_status_buf} : registers[addr_stage2_buf])) : rdata;

    always @(posedge clk) begin
        if (!rst_n) begin
            ready <= 1;
            irq <= 0;
            irq_status <= 0;
            irq_status_buf <= 0;
            irq_enable <= 0;
            valid_stage1 <= 0;
            valid_stage2 <= 0;
        end else begin
            // Pipeline stage 1
            if (wr_en && ready) begin
                wdata_stage1 <= wdata;
                addr_stage1 <= addr;
                wr_en_stage1 <= wr_en;
                valid_stage1 <= 1;
                ready_stage1 <= 0;
            end else if (rd_en && ready) begin
                addr_stage1 <= addr;
                rd_en_stage1 <= rd_en;
                valid_stage1 <= 1;
                ready_stage1 <= 0;
            end else if (!ready) begin
                ready_stage1 <= 1;
            end

            // Pipeline stage 2
            if (valid_stage1) begin
                wdata_stage2 <= wdata_stage1;
                addr_stage2 <= addr_stage1;
                wr_en_stage2 <= wr_en_stage1;
                rd_en_stage2 <= rd_en_stage1;
                valid_stage2 <= 1;
                valid_stage1 <= 0;
            end

            // Buffer stage for high fanout signals
            if (valid_stage2) begin
                wdata_stage2_buf <= wdata_stage2;
                addr_stage2_buf <= addr_stage2;
                irq_status_buf <= irq_status;
            end

            // Handle register access
            if (valid_stage2) begin
                if (wr_en_stage2) begin
                    if (!addr_in_special_range) begin
                        registers[addr_stage2_buf] <= wdata_stage2_buf;
                    end
                    irq_enable <= irq_enable_next;
                    irq_status <= irq_status_next;
                end
                rdata <= rdata_next;
                ready <= 0;
                valid_stage2 <= 0;
            end else if (!ready) begin
                ready <= 1;
            end
            
            // Interrupt generation
            irq <= |(irq_status_buf & irq_enable);
        end
    end
endmodule