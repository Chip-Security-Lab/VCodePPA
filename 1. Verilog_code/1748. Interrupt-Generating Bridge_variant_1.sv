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

    // Stage 1: Input Buffering
    reg [AWIDTH-1:0] addr_stage1;
    reg [DWIDTH-1:0] wdata_stage1;
    reg wr_en_stage1, rd_en_stage1;
    reg valid_stage1;

    // Stage 2: Register Access
    reg [AWIDTH-1:0] addr_stage2;
    reg [DWIDTH-1:0] wdata_stage2;
    reg wr_en_stage2, rd_en_stage2;
    reg valid_stage2;
    reg [DWIDTH-1:0] registers [0:2**AWIDTH-1];
    reg [7:0] irq_status_stage2, irq_enable_stage2;

    // Stage 3: Read Data and Interrupt Generation
    reg [DWIDTH-1:0] rdata_stage3;
    reg ready_stage3;
    reg [7:0] irq_status_stage3, irq_enable_stage3;
    reg valid_stage3;

    // Stage 1: Input Buffering
    always @(posedge clk) begin
        if (!rst_n) begin
            addr_stage1 <= 0;
            wdata_stage1 <= 0;
            wr_en_stage1 <= 0;
            rd_en_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            addr_stage1 <= addr;
            wdata_stage1 <= wdata;
            wr_en_stage1 <= wr_en;
            rd_en_stage1 <= rd_en;
            valid_stage1 <= wr_en || rd_en;
        end
    end

    // Stage 2: Register Access
    always @(posedge clk) begin
        if (!rst_n) begin
            addr_stage2 <= 0;
            wdata_stage2 <= 0;
            wr_en_stage2 <= 0;
            rd_en_stage2 <= 0;
            valid_stage2 <= 0;
            irq_status_stage2 <= 0;
            irq_enable_stage2 <= 0;
        end else begin
            addr_stage2 <= addr_stage1;
            wdata_stage2 <= wdata_stage1;
            wr_en_stage2 <= wr_en_stage1;
            rd_en_stage2 <= rd_en_stage1;
            valid_stage2 <= valid_stage1;

            if (valid_stage1 && wr_en_stage1) begin
                registers[addr_stage1] <= wdata_stage1;
                if (addr_stage1 == 8'hFE) irq_enable_stage2 <= wdata_stage1[7:0];
                else if (addr_stage1 == 8'hFF) irq_status_stage2 <= irq_status_stage2 & ~wdata_stage1[7:0];
                if (addr_stage1 >= 8'h80 && addr_stage1 < 8'hA0) begin
                    irq_status_stage2[0] <= 1;
                end
            end
        end
    end

    // Stage 3: Read Data and Interrupt Generation
    always @(posedge clk) begin
        if (!rst_n) begin
            rdata_stage3 <= 0;
            ready_stage3 <= 1;
            irq_status_stage3 <= 0;
            irq_enable_stage3 <= 0;
            valid_stage3 <= 0;
        end else begin
            valid_stage3 <= valid_stage2;
            irq_status_stage3 <= irq_status_stage2;
            irq_enable_stage3 <= irq_enable_stage2;

            if (valid_stage2) begin
                if (rd_en_stage2) begin
                    if (addr_stage2 == 8'hFE) rdata_stage3 <= {24'b0, irq_enable_stage2};
                    else if (addr_stage2 == 8'hFF) rdata_stage3 <= {24'b0, irq_status_stage2};
                    else rdata_stage3 <= registers[addr_stage2];
                end
                ready_stage3 <= 0;
            end else begin
                ready_stage3 <= 1;
            end
        end
    end

    // Output assignments
    assign rdata = rdata_stage3;
    assign ready = ready_stage3;
    assign irq = |(irq_status_stage3 & irq_enable_stage3);

endmodule