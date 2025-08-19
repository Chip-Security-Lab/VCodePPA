//SystemVerilog
module width_reducer #(
    parameter IN_WIDTH = 32,
    parameter OUT_WIDTH = 8  // IN_WIDTH必须是OUT_WIDTH的整数倍
)(
    input wire clk,
    input wire reset,
    input wire in_valid,
    input wire [IN_WIDTH-1:0] data_in,
    output wire [OUT_WIDTH-1:0] data_out,
    output wire out_valid,
    output wire ready_for_input
);
    localparam RATIO = IN_WIDTH / OUT_WIDTH;
    localparam CNT_WIDTH = $clog2(RATIO);

    reg [IN_WIDTH-1:0] data_buffer;
    reg [CNT_WIDTH-1:0] output_count;
    reg output_valid_reg, processing_reg;

    wire [IN_WIDTH-1:0] shifted_data;
    wire [CNT_WIDTH-1:0] incremented_count;

    // Subtract LUT for 5-bit operands (since CNT_WIDTH<=5 for 32/8=4)
    function [4:0] lut_sub_5bit;
        input [4:0] a;
        input [4:0] b;
        reg [4:0] sub_lut [0:31][0:31];
        integer i, j;
        begin
            // Initialize LUT once
            for (i = 0; i < 32; i = i + 1)
                for (j = 0; j < 32; j = j + 1)
                    sub_lut[i][j] = i - j;
            lut_sub_5bit = sub_lut[a][b];
        end
    endfunction

    // LUT for OUT_WIDTH shift (possible values: 8, 16, 32)
    function [IN_WIDTH-1:0] lut_shift_right;
        input [IN_WIDTH-1:0] din;
        input [4:0] shift_amt;
        reg [IN_WIDTH-1:0] shift_lut [0:31];
        integer k;
        begin
            for (k = 0; k < 32; k = k + 1)
                shift_lut[k] = din >> k;
            lut_shift_right = shift_lut[shift_amt];
        end
    endfunction

    // LUT for increment operation
    function [CNT_WIDTH-1:0] lut_increment;
        input [CNT_WIDTH-1:0] din;
        reg [CNT_WIDTH-1:0] inc_lut [0:31];
        integer l;
        begin
            for (l = 0; l < 32; l = l + 1)
                inc_lut[l] = l + 1;
            lut_increment = inc_lut[din];
        end
    endfunction

    always @(posedge clk) begin
        if (reset) begin
            output_count     <= {CNT_WIDTH{1'b0}};
            data_buffer      <= {IN_WIDTH{1'b0}};
            output_valid_reg <= 1'b0;
            processing_reg   <= 1'b0;
        end else if (in_valid && !processing_reg) begin
            data_buffer      <= data_in;
            output_count     <= {CNT_WIDTH{1'b0}};
            output_valid_reg <= 1'b1;
            processing_reg   <= 1'b1;
        end else if (processing_reg) begin
            if (lut_sub_5bit(output_count, {CNT_WIDTH{1'b0}}) < (RATIO-1)) begin
                output_count     <= lut_increment(output_count);
                data_buffer      <= lut_shift_right(data_buffer, OUT_WIDTH);
            end else begin
                processing_reg   <= 1'b0;
                output_valid_reg <= 1'b0;
            end
        end
    end

    assign data_out = data_buffer[OUT_WIDTH-1:0];
    assign out_valid = output_valid_reg;
    assign ready_for_input = ~processing_reg;
endmodule