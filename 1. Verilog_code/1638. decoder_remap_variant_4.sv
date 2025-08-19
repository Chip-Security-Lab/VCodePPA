//SystemVerilog
module decoder_remap (
    input clk,
    input rst_n,
    input [7:0] base_addr,
    input [7:0] addr,
    output reg select,
    output reg valid
);

// Pipeline registers
reg [7:0] addr_stage1;
reg [7:0] base_addr_stage1;
reg valid_stage1;

reg [7:0] addr_diff;
reg valid_stage2;

reg [3:0] upper_bits;
reg valid_stage3;

// Stage 1: Input registration
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_stage1 <= 8'h0;
        base_addr_stage1 <= 8'h0;
        valid_stage1 <= 1'b0;
    end else begin
        addr_stage1 <= addr;
        base_addr_stage1 <= base_addr;
        valid_stage1 <= 1'b1;
    end
end

// Stage 2: Address subtraction
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_diff <= 8'h0;
        valid_stage2 <= 1'b0;
    end else begin
        addr_diff <= addr_stage1 - base_addr_stage1;
        valid_stage2 <= valid_stage1;
    end
end

// Stage 3: Upper bits extraction
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        upper_bits <= 4'h0;
        valid_stage3 <= 1'b0;
    end else begin
        upper_bits <= addr_diff[7:4];
        valid_stage3 <= valid_stage2;
    end
end

// Stage 4: Output generation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        select <= 1'b0;
        valid <= 1'b0;
    end else begin
        select <= ~|upper_bits;  // Optimized comparison for addr_diff < 16
        valid <= valid_stage3;
    end
end

endmodule