//SystemVerilog
module decoder_remap (
    input clk,
    input rst_n,
    input valid_in,
    output reg ready_out,
    input [7:0] base_addr,
    input [7:0] addr,
    output reg valid_out,
    input ready_in,
    output reg select
);

// Pipeline stage 1: Address calculation
reg [7:0] addr_diff_stage1;
reg [7:0] base_addr_stage1;
reg valid_stage1;

// Pipeline stage 2: Range check
reg [7:0] addr_diff_stage2;
reg range_check_stage2;
reg valid_stage2;

// Pipeline stage 3: Output
reg range_check_stage3;
reg valid_stage3;

// Ready signal generation
wire ready_stage1 = ~valid_stage1 || ready_stage2;
wire ready_stage2 = ~valid_stage2 || ready_stage3;
wire ready_stage3 = ~valid_stage3 || ready_in;

// Stage 1: Address calculation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_diff_stage1 <= 8'h0;
        base_addr_stage1 <= 8'h0;
        valid_stage1 <= 1'b0;
    end else if (valid_in && ready_stage1) begin
        addr_diff_stage1 <= addr - base_addr;
        base_addr_stage1 <= base_addr;
        valid_stage1 <= 1'b1;
    end else if (!valid_in || !ready_stage1) begin
        valid_stage1 <= 1'b0;
    end
end

// Stage 2: Range check
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_diff_stage2 <= 8'h0;
        range_check_stage2 <= 1'b0;
        valid_stage2 <= 1'b0;
    end else if (valid_stage1 && ready_stage2) begin
        addr_diff_stage2 <= addr_diff_stage1;
        range_check_stage2 <= (addr_diff_stage1 < 8'h10);
        valid_stage2 <= 1'b1;
    end else if (!valid_stage1 || !ready_stage2) begin
        valid_stage2 <= 1'b0;
    end
end

// Stage 3: Output
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        range_check_stage3 <= 1'b0;
        valid_stage3 <= 1'b0;
    end else if (valid_stage2 && ready_stage3) begin
        range_check_stage3 <= range_check_stage2;
        valid_stage3 <= 1'b1;
    end else if (!valid_stage2 || !ready_stage3) begin
        valid_stage3 <= 1'b0;
    end
end

// Output assignment
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        select <= 1'b0;
        valid_out <= 1'b0;
    end else if (valid_stage3 && ready_in) begin
        select <= range_check_stage3;
        valid_out <= 1'b1;
    end else if (!valid_stage3 || !ready_in) begin
        valid_out <= 1'b0;
    end
end

// Ready signal assignment
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ready_out <= 1'b0;
    end else begin
        ready_out <= ready_stage1;
    end
end

endmodule