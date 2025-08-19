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

    // Pipeline registers for optimization
    reg [DWIDTH-1:0] wdata_reg;
    reg [AWIDTH-1:0] addr_reg;
    reg wr_en_reg, rd_en_reg;
    reg ready_reg;

    always @(posedge clk) begin
        if (!rst_n) begin
            reset_signals();
        end else begin
            pipeline_registers();
            handle_register_access();
            generate_interrupt();
        end
    end

    // Reset signals
    task reset_signals();
        ready <= 1;
        irq <= 0;
        irq_status <= 0;
        irq_enable <= 0;
        wdata_reg <= 0;
        addr_reg <= 0;
        wr_en_reg <= 0;
        rd_en_reg <= 0;
        ready_reg <= 1;
    endtask

    // Pipeline stage: Register inputs
    task pipeline_registers();
        wdata_reg <= wdata;
        addr_reg <= addr;
        wr_en_reg <= wr_en;
        rd_en_reg <= rd_en;
    endtask

    // Handle register access
    task handle_register_access();
        if (wr_en_reg && ready_reg) begin
            write_register();
        end else if (rd_en_reg && ready_reg) begin
            read_register();
        end else if (!ready_reg) begin
            ready_reg <= 1;
        end
    endtask

    // Write to register
    task write_register();
        registers[addr_reg] <= wdata_reg;
        ready_reg <= 0;

        // Special registers
        if (addr_reg == 8'hFE) irq_enable <= wdata_reg[7:0];
        else if (addr_reg == 8'hFF) irq_status <= irq_status & ~wdata_reg[7:0]; // Clear on write

        // Generate interrupt on specific addresses
        if (addr_reg >= 8'h80 && addr_reg < 8'hA0) begin
            irq_status[0] <= 1;
        end
    endtask

    // Read from register
    task read_register();
        if (addr_reg == 8'hFE) rdata <= {24'b0, irq_enable};
        else if (addr_reg == 8'hFF) rdata <= {24'b0, irq_status};
        else rdata <= registers[addr_reg];
        ready_reg <= 0;
    endtask

    // Interrupt generation
    task generate_interrupt();
        irq <= |(irq_status & irq_enable);
    endtask
endmodule