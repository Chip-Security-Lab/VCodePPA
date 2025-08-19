//SystemVerilog
module rom_cdc_pipeline #(parameter DW=64)(
    input wr_clk,
    input rd_clk,
    input [3:0] addr,
    output reg [DW-1:0] q
);
    reg [DW-1:0] mem [0:15];
    reg [3:0] sync_addr_stage1, sync_addr_stage2;
    reg [DW-1:0] q_stage1;
    reg valid_stage1, valid_stage2;

    // Initialize memory
    integer i;
    initial begin
        for (i = 0; i < 16; i = i + 1)
            mem[i] = {DW{1'b0}} | i;
    end

    // Pipeline stage 1: Synchronize address
    always @(posedge rd_clk) begin
        sync_addr_stage1 <= addr;
        valid_stage1 <= 1'b1;
    end

    // Pipeline stage 2: Transfer synchronized address
    always @(posedge rd_clk) begin
        if (valid_stage1) begin
            sync_addr_stage2 <= sync_addr_stage1;
        end
    end

    // Pipeline stage 3: Read from memory
    always @(posedge rd_clk) begin
        if (valid_stage1) begin
            q_stage1 <= mem[sync_addr_stage2];
            valid_stage2 <= 1'b1;
        end else begin
            valid_stage2 <= 1'b0;
        end
    end

    // Output stage
    always @(posedge rd_clk) begin
        if (valid_stage2) begin
            q <= q_stage1;
        end
    end

    // Reset logic (optional)
    always @(posedge wr_clk) begin
        // No write operations in this simplified example
    end
endmodule