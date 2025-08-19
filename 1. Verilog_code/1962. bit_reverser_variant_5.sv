//SystemVerilog
module bit_reverser #(
    parameter WIDTH = 8
)(
    input                  clk,
    input                  rst_n,
    input                  data_valid,
    input  [WIDTH-1:0]     data_in,
    output reg             data_out_valid,
    output reg [WIDTH-1:0] data_out
);

    // Pipeline Stage 1: Input Registering
    reg [WIDTH-1:0] reg_data_in_stage1;
    reg             reg_valid_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_data_in_stage1 <= {WIDTH{1'b0}};
            reg_valid_stage1   <= 1'b0;
        end else begin
            reg_data_in_stage1 <= data_in;
            reg_valid_stage1   <= data_valid;
        end
    end

    // Pipeline Stage 2: Balanced Bit-Reversal Logic
    reg [WIDTH-1:0] reg_data_reversed_stage2;
    reg             reg_valid_stage2;

    // Balanced tree-based bit-reversal
    function [WIDTH-1:0] balanced_bit_reverse;
        input [WIDTH-1:0] in_data;
        integer idx, j, half, stage;
        reg [WIDTH-1:0] temp [0:7];
        begin
            temp[0] = in_data;
            for (stage = 0; (1 << stage) < WIDTH; stage = stage + 1) begin
                half = 1 << stage;
                temp[stage+1] = temp[stage];
                for (idx = 0; idx < WIDTH; idx = idx + 1) begin
                    j = idx ^ half;
                    if (j > idx) begin
                        temp[stage+1][idx] = temp[stage][j];
                        temp[stage+1][j]   = temp[stage][idx];
                    end
                end
            end
            balanced_bit_reverse = temp[stage];
        end
    endfunction

    wire [WIDTH-1:0] bit_reversed_data;
    assign bit_reversed_data = balanced_bit_reverse(reg_data_in_stage1);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_data_reversed_stage2 <= {WIDTH{1'b0}};
            reg_valid_stage2         <= 1'b0;
        end else begin
            reg_data_reversed_stage2 <= bit_reversed_data;
            reg_valid_stage2         <= reg_valid_stage1;
        end
    end

    // Pipeline Stage 3: Output Registering
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out       <= {WIDTH{1'b0}};
            data_out_valid <= 1'b0;
        end else begin
            data_out       <= reg_data_reversed_stage2;
            data_out_valid <= reg_valid_stage2;
        end
    end

endmodule