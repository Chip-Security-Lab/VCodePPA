//SystemVerilog
module decoder_window #(AW=16) (
    input clk,
    input rst_n,
    input [AW-1:0] base_addr,
    input [AW-1:0] window_size,
    input [AW-1:0] addr_in,
    output reg valid
);

// Stage 1: Register inputs
reg [AW-1:0] addr_reg_stage1;
reg [AW-1:0] base_addr_reg_stage1;
reg [AW-1:0] window_size_reg_stage1;

// Stage 2: Partial address comparison
reg [AW-1:0] addr_reg_stage2;
reg [AW-1:0] base_addr_reg_stage2;
reg [AW-1:0] window_size_reg_stage2;
reg addr_greater_equal_base;

// Stage 3: Final validation
reg [AW-1:0] addr_reg_stage3;
reg [AW-1:0] base_addr_reg_stage3;
reg [AW-1:0] window_size_reg_stage3;
reg addr_greater_equal_base_reg;
reg addr_less_upper_bound;

// Stage 4: Final output
reg valid_stage4;

// Stage 1: Register inputs
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_reg_stage1 <= {AW{1'b0}};
        base_addr_reg_stage1 <= {AW{1'b0}};
        window_size_reg_stage1 <= {AW{1'b0}};
    end else begin
        addr_reg_stage1 <= addr_in;
        base_addr_reg_stage1 <= base_addr;
        window_size_reg_stage1 <= window_size;
    end
end

// Stage 2: Partial address comparison
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_reg_stage2 <= {AW{1'b0}};
        base_addr_reg_stage2 <= {AW{1'b0}};
        window_size_reg_stage2 <= {AW{1'b0}};
        addr_greater_equal_base <= 1'b0;
    end else begin
        addr_reg_stage2 <= addr_reg_stage1;
        base_addr_reg_stage2 <= base_addr_reg_stage1;
        window_size_reg_stage2 <= window_size_reg_stage1;
        addr_greater_equal_base <= (addr_reg_stage1 >= base_addr_reg_stage1);
    end
end

// Stage 3: Final validation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_reg_stage3 <= {AW{1'b0}};
        base_addr_reg_stage3 <= {AW{1'b0}};
        window_size_reg_stage3 <= {AW{1'b0}};
        addr_greater_equal_base_reg <= 1'b0;
        addr_less_upper_bound <= 1'b0;
    end else begin
        addr_reg_stage3 <= addr_reg_stage2;
        base_addr_reg_stage3 <= base_addr_reg_stage2;
        window_size_reg_stage3 <= window_size_reg_stage2;
        addr_greater_equal_base_reg <= addr_greater_equal_base;
        addr_less_upper_bound <= (addr_reg_stage2 < (base_addr_reg_stage2 + window_size_reg_stage2));
    end
end

// Stage 4: Final output
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_stage4 <= 1'b0;
    end else begin
        valid_stage4 <= addr_greater_equal_base_reg && addr_less_upper_bound;
    end
end

// Output assignment
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid <= 1'b0;
    end else begin
        valid <= valid_stage4;
    end
end

endmodule