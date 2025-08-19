//SystemVerilog
module base_addr_decoder #(
    parameter BASE_ADDR = 4'h0
)(
    input clk,
    input rst_n,
    input [3:0] addr,
    output reg cs,
    output reg valid_out
);

    // Pipeline stage 1 signals
    reg [3:0] addr_stage1;
    reg valid_stage1;

    // Pipeline stage 2 signals
    reg [3:0] addr_stage2;
    reg valid_stage2;

    // Pipeline stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 4'b0;
            valid_stage1 <= 1'b0;
        end else begin
            addr_stage1 <= addr;
            valid_stage1 <= 1'b1;
        end
    end

    // Pipeline stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage2 <= 4'b0;
            valid_stage2 <= 1'b0;
        end else begin
            addr_stage2 <= addr_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cs <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            cs <= (addr_stage2[3:2] == BASE_ADDR[3:2]) & valid_stage2;
            valid_out <= valid_stage2;
        end
    end

endmodule