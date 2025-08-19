//SystemVerilog
module addr_comparator #(parameter AW=16) (
    input clk,
    input rst_n,
    input [AW-1:0] addr,
    input [AW-1:0] base,
    input [AW-1:0] size,
    output reg is_valid
);

    reg [AW-1:0] addr_stage1;
    reg [AW-1:0] base_stage1;
    reg [AW-1:0] size_stage1;
    reg [AW-1:0] sum_stage2;
    reg valid_stage1;
    reg valid_stage2;

    // Stage 1: Register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 0;
            base_stage1 <= 0;
            size_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            addr_stage1 <= addr;
            base_stage1 <= base;
            size_stage1 <= size;
            valid_stage1 <= 1'b1;
        end
    end

    // Stage 2: Calculate base + size
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            sum_stage2 <= base_stage1 + size_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: Final comparison
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            is_valid <= 0;
        end else begin
            is_valid <= valid_stage2 && (addr_stage1 >= base_stage1) && (addr_stage1 < sum_stage2);
        end
    end

endmodule

module addr_register #(parameter AW=16) (
    input clk,
    input rst_n,
    input [AW-1:0] addr_in,
    output reg [AW-1:0] addr_out
);

    reg [AW-1:0] addr_stage1;
    reg valid_stage1;

    // Stage 1: Register input
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            addr_stage1 <= addr_in;
            valid_stage1 <= 1'b1;
        end
    end

    // Stage 2: Output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_out <= 0;
        end else begin
            addr_out <= addr_stage1;
        end
    end

endmodule

module decoder_window #(parameter AW=16) (
    input clk,
    input rst_n,
    input [AW-1:0] base_addr,
    input [AW-1:0] window_size,
    input [AW-1:0] addr_in,
    output reg valid
);

    reg [AW-1:0] addr_stage1;
    reg [AW-1:0] base_stage1;
    reg [AW-1:0] size_stage1;
    reg [AW-1:0] sum_stage2;
    reg valid_stage1;
    reg valid_stage2;

    // Stage 1: Register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 0;
            base_stage1 <= 0;
            size_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            addr_stage1 <= addr_in;
            base_stage1 <= base_addr;
            size_stage1 <= window_size;
            valid_stage1 <= 1'b1;
        end
    end

    // Stage 2: Calculate base + size
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            sum_stage2 <= base_stage1 + size_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: Final comparison
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid <= 0;
        end else begin
            valid <= valid_stage2 && (addr_stage1 >= base_stage1) && (addr_stage1 < sum_stage2);
        end
    end

endmodule