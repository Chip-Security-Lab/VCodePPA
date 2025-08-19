//SystemVerilog
module decoder_window #(AW=16) (
    input clk,
    input rst_n,
    input [AW-1:0] base_addr,
    input [AW-1:0] window_size,
    input [AW-1:0] addr_in,
    output reg valid
);

// Pipeline stage 1 registers
reg [AW-1:0] addr_stage1;
reg [AW-1:0] base_addr_stage1;
reg [AW-1:0] window_size_stage1;
reg valid_stage1;

// Pipeline stage 2 registers
reg [AW-1:0] addr_stage2;
reg [AW-1:0] upper_bound_stage2;
reg valid_stage2;
reg [AW-1:0] base_addr_stage2;

// Pipeline stage 3 registers
reg valid_stage3;
reg [AW-1:0] addr_stage3;
reg [AW-1:0] upper_bound_stage3;
reg [AW-1:0] base_addr_stage3;

// Stage 1: Register inputs
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_stage1 <= 0;
        base_addr_stage1 <= 0;
        window_size_stage1 <= 0;
        valid_stage1 <= 0;
    end else begin
        addr_stage1 <= addr_in;
        base_addr_stage1 <= base_addr;
        window_size_stage1 <= window_size;
        valid_stage1 <= 1'b1;
    end
end

// Stage 2: Calculate upper bound
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_stage2 <= 0;
        upper_bound_stage2 <= 0;
        valid_stage2 <= 0;
        base_addr_stage2 <= 0;
    end else begin
        addr_stage2 <= addr_stage1;
        upper_bound_stage2 <= base_addr_stage1 + window_size_stage1;
        valid_stage2 <= valid_stage1;
        base_addr_stage2 <= base_addr_stage1;
    end
end

// Stage 3: Register intermediate values
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_stage3 <= 0;
        upper_bound_stage3 <= 0;
        base_addr_stage3 <= 0;
        valid_stage3 <= 0;
    end else begin
        addr_stage3 <= addr_stage2;
        upper_bound_stage3 <= upper_bound_stage2;
        base_addr_stage3 <= base_addr_stage2;
        valid_stage3 <= valid_stage2;
    end
end

// Stage 4: Compare and generate valid signal
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid <= 0;
    end else begin
        valid <= valid_stage3 && 
                (addr_stage3 >= base_addr_stage3) && 
                (addr_stage3 < upper_bound_stage3);
    end
end

endmodule