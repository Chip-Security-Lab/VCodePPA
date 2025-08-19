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

    // Memory registers
    reg [DWIDTH-1:0] registers [0:2**AWIDTH-1];
    
    // Control registers
    reg [7:0] irq_status, irq_enable;
    
    // IRQ generation pipeline
    reg [7:0] irq_status_for_irq;
    reg [7:0] irq_enable_for_irq;
    reg irq_internal;
    
    // Pipeline stages
    reg [AWIDTH-1:0] addr_stage [0:3];
    reg [DWIDTH-1:0] wdata_stage [0:3];
    reg wr_en_stage [0:3], rd_en_stage [0:3], valid_stage [0:3];
    reg [7:0] irq_status_update_stage, irq_enable_update_stage;
    reg update_irq_status_stage, update_irq_enable_stage;

    // Stage 1: Request capture
    always @(posedge clk) begin
        if (!rst_n) begin
            valid_stage[0] <= 0;
            wr_en_stage[0] <= 0;
            rd_en_stage[0] <= 0;
            addr_stage[0] <= 0;
            wdata_stage[0] <= 0;
        end else begin
            if (ready && (wr_en || rd_en)) begin
                valid_stage[0] <= 1;
                wr_en_stage[0] <= wr_en;
                rd_en_stage[0] <= rd_en;
                addr_stage[0] <= addr;
                wdata_stage[0] <= wdata;
            end else if (!valid_stage[3] && !valid_stage[2] && !valid_stage[1]) begin
                valid_stage[0] <= 0;
            end
        end
    end

    // Stage 2: Address decode
    always @(posedge clk) begin
        if (!rst_n) begin
            valid_stage[1] <= 0;
            wr_en_stage[1] <= 0;
            rd_en_stage[1] <= 0;
            addr_stage[1] <= 0;
            wdata_stage[1] <= 0;
        end else begin
            valid_stage[1] <= valid_stage[0];
            wr_en_stage[1] <= wr_en_stage[0];
            rd_en_stage[1] <= rd_en_stage[0];
            addr_stage[1] <= addr_stage[0];
            wdata_stage[1] <= wdata_stage[0];
        end
    end

    // Stage 3: Memory/register access
    always @(posedge clk) begin
        if (!rst_n) begin
            valid_stage[2] <= 0;
            wr_en_stage[2] <= 0;
            rd_en_stage[2] <= 0;
        end else begin
            valid_stage[2] <= valid_stage[1];
            wr_en_stage[2] <= wr_en_stage[1];
            rd_en_stage[2] <= rd_en_stage[1];

            if (valid_stage[1]) begin
                if (wr_en_stage[1]) begin
                    if (addr_stage[1] == 8'hFE) begin
                        update_irq_enable_stage <= 1;
                        irq_enable_update_stage <= wdata_stage[1][7:0];
                    end else if (addr_stage[1] == 8'hFF) begin
                        update_irq_status_stage <= 1;
                        irq_status_update_stage <= irq_status & ~wdata_stage[1][7:0]; // Clear on write
                    end else begin
                        registers[addr_stage[1]] <= wdata_stage[1];
                    end
                end else if (rd_en_stage[1]) begin
                    if (addr_stage[1] == 8'hFE) begin
                        rdata <= {24'b0, irq_enable};
                    end else if (addr_stage[1] == 8'hFF) begin
                        rdata <= {24'b0, irq_status};
                    end else begin
                        rdata <= registers[addr_stage[1]];
                    end
                end
            end
        end
    end

    // Stage 4: Writeback/completion
    always @(posedge clk) begin
        if (!rst_n) begin
            valid_stage[3] <= 0;
            ready <= 1;
        end else begin
            valid_stage[3] <= valid_stage[2];
            if (valid_stage[3]) begin
                ready <= 1;
                if (rd_en_stage[2]) begin
                    rdata <= rdata;
                end
                valid_stage[3] <= 0;
            end else if (ready && (wr_en || rd_en)) begin
                ready <= 0;
            end
        end
    end

    // IRQ Status and Enable registers update
    always @(posedge clk) begin
        if (!rst_n) begin
            irq_status <= 0;
            irq_enable <= 0;
        end else begin
            if (valid_stage[2] && update_irq_status_stage) begin
                irq_status <= irq_status_update_stage;
            end
            
            if (valid_stage[2] && update_irq_enable_stage) begin
                irq_enable <= irq_enable_update_stage;
            end
        end
    end

    // IRQ generation pipeline
    always @(posedge clk) begin
        if (!rst_n) begin
            irq_status_for_irq <= 0;
            irq_enable_for_irq <= 0;
            irq_internal <= 0;
            irq <= 0;
        end else begin
            irq_status_for_irq <= irq_status;
            irq_enable_for_irq <= irq_enable;
            irq_internal <= |(irq_status_for_irq & irq_enable_for_irq);
            irq <= irq_internal;
        end
    end
endmodule