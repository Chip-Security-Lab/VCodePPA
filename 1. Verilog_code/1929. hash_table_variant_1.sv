//SystemVerilog
module hash_table #(
    parameter DW = 8,
    parameter TABLE_SIZE = 16
)(
    input                  clk,
    input                  rst_n,
    input                  valid_in,
    input  [DW-1:0]        key_in,
    output                 valid_out,
    output reg [DW-1:0]    hash_out
);

    // Stage 1: Input register
    reg [DW-1:0] key_stage1;
    reg          valid_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_stage1   <= {DW{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            key_stage1   <= key_in;
            valid_stage1 <= valid_in;
        end
    end

    // Stage 2: Multiply key by 8'h9E
    reg [DW+7:0] mul_stage2;
    reg          valid_stage2;
    reg [DW-1:0] key_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mul_stage2   <= {(DW+8){1'b0}};
            key_stage2   <= {DW{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            mul_stage2   <= key_stage1 * 8'h9E;
            key_stage2   <= key_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: Modulo operation
    reg [DW-1:0] hash_stage3;
    reg          valid_stage3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hash_stage3  <= {DW{1'b0}};
            valid_stage3 <= 1'b0;
        end else begin
            hash_stage3  <= mul_stage2 % TABLE_SIZE;
            valid_stage3 <= valid_stage2;
        end
    end

    // Stage 4: Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hash_out   <= {DW{1'b0}};
        end else begin
            hash_out   <= hash_stage3;
        end
    end

    assign valid_out = valid_stage3;

endmodule