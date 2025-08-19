//SystemVerilog
module addr_trans_bridge_pipeline #(parameter DWIDTH=32, AWIDTH=16) (
    input clk, rst_n,
    input [AWIDTH-1:0] src_addr,
    input [DWIDTH-1:0] src_data,
    input src_valid,
    output reg src_ready,
    output reg [AWIDTH-1:0] dst_addr,
    output reg [DWIDTH-1:0] dst_data,
    output reg dst_valid,
    input dst_ready
);

    reg [AWIDTH-1:0] base_addr = 'h1000;  // Example base address
    reg [AWIDTH-1:0] limit_addr = 'h2000; // Example limit

    // Pipeline registers
    reg [AWIDTH-1:0] addr_stage1, addr_stage2;
    reg [DWIDTH-1:0] data_stage1, data_stage2;
    reg valid_stage1, valid_stage2;

    always @(posedge clk) begin
        if (!rst_n) begin
            dst_valid <= 0; 
            src_ready <= 1;
            valid_stage1 <= 0;
            valid_stage2 <= 0;
        end else begin
            // Stage 1: Capture inputs
            if (src_valid && src_ready) begin
                addr_stage1 <= src_addr;
                data_stage1 <= src_data;
                valid_stage1 <= 1;
                src_ready <= 0;
            end else if (dst_valid && dst_ready) begin
                valid_stage1 <= 0;
                src_ready <= 1;
            end

            // Stage 2: Process data
            if (valid_stage1) begin
                if (addr_stage1 >= base_addr && addr_stage1 < limit_addr) begin
                    addr_stage2 <= addr_stage1 - base_addr;
                    data_stage2 <= data_stage1;
                    valid_stage2 <= 1;
                end else begin
                    valid_stage2 <= 0;
                end
            end

            // Output stage
            if (valid_stage2) begin
                dst_addr <= addr_stage2;
                dst_data <= data_stage2;
                dst_valid <= 1;
            end else if (dst_valid && dst_ready) begin
                dst_valid <= 0;
            end
        end
    end
endmodule