//SystemVerilog
module sync_left_logical_shifter #(
    parameter DATA_WIDTH = 8,
    parameter SHIFT_WIDTH = 3
)(
    input wire clk,
    input wire rst_n,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire [SHIFT_WIDTH-1:0] shift_amount,
    output reg [DATA_WIDTH-1:0] data_out
);

    // Pipeline registers
    reg [DATA_WIDTH-1:0] data_stage1;
    reg [SHIFT_WIDTH-1:0] shift_stage1;
    reg [DATA_WIDTH-1:0] data_stage2;
    reg [SHIFT_WIDTH-1:0] shift_stage2;
    reg [DATA_WIDTH-1:0] data_stage3;
    reg [SHIFT_WIDTH-1:0] shift_stage3;

    // Stage 1: Input register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= {DATA_WIDTH{1'b0}};
            shift_stage1 <= {SHIFT_WIDTH{1'b0}};
        end else begin
            data_stage1 <= data_in;
            shift_stage1 <= shift_amount;
        end
    end

    // Stage 2: First shift operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= {DATA_WIDTH{1'b0}};
            shift_stage2 <= {SHIFT_WIDTH{1'b0}};
        end else begin
            data_stage2 <= data_stage1 << (shift_stage1 & 3'b100);
            shift_stage2 <= shift_stage1;
        end
    end

    // Stage 3: Second shift operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage3 <= {DATA_WIDTH{1'b0}};
            shift_stage3 <= {SHIFT_WIDTH{1'b0}};
        end else begin
            data_stage3 <= data_stage2 << (shift_stage2 & 3'b010);
            shift_stage3 <= shift_stage2;
        end
    end

    // Stage 4: Final shift operation and output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {DATA_WIDTH{1'b0}};
        end else begin
            data_out <= data_stage3 << (shift_stage3 & 3'b001);
        end
    end

endmodule