//SystemVerilog
module RegEnMux_Pipelined #(parameter DW=8) (
    input clk,
    input rst_n,
    input en,
    input [1:0] sel,
    input [3:0][DW-1:0] din,
    output reg [DW-1:0] dout,
    output reg valid_out
);

    // Stage 1: Register inputs
    reg en_stage1;
    reg [1:0] sel_stage1;
    reg [3:0][DW-1:0] din_stage1;
    reg valid_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en_stage1      <= 1'b0;
            sel_stage1     <= 2'b0;
            din_stage1     <= {4{ {DW{1'b0}} }};
            valid_stage1   <= 1'b0;
        end else begin
            en_stage1      <= en;
            sel_stage1     <= sel;
            din_stage1     <= din;
            valid_stage1   <= en;
        end
    end

    // Stage 2: Mux selection and 4-bit conditional inversion subtractor
    reg [DW-1:0] mux_out_stage2;
    reg valid_stage2;

    // Subtractor signals for 4-bit conditional inversion subtractor
    reg [3:0] minuend;
    reg [3:0] subtrahend;
    reg subtract_enable; // enable subtraction
    reg sub_invert;      // conditional inversion control
    reg [3:0] subtrahend_xor;
    reg [3:0] sum_result;
    reg carry_in;
    reg carry_out;
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mux_out_stage2 <= {DW{1'b0}};
            valid_stage2   <= 1'b0;
        end else begin
            if (valid_stage1 && en_stage1) begin
                // Example: when sel_stage1 == 3, perform subtraction (din_stage1[2] - din_stage1[3]) using conditional inversion subtractor
                // Other sel: normal mux
                if (sel_stage1 == 2'd3) begin
                    minuend        <= din_stage1[2][3:0];
                    subtrahend     <= din_stage1[3][3:0];
                    subtract_enable<= 1'b1;
                    sub_invert     <= 1'b1; // subtract: invert subtrahend
                    carry_in       <= 1'b1;

                    // Conditional inversion of subtrahend
                    for (i = 0; i < 4; i = i + 1) begin
                        subtrahend_xor[i] = subtrahend[i] ^ sub_invert;
                    end
                    // Ripple carry adder (4-bit)
                    sum_result[0] = minuend[0] ^ subtrahend_xor[0] ^ carry_in;
                    carry_out     = (minuend[0] & subtrahend_xor[0]) | (minuend[0] & carry_in) | (subtrahend_xor[0] & carry_in);

                    sum_result[1] = minuend[1] ^ subtrahend_xor[1] ^ carry_out;
                    carry_out     = (minuend[1] & subtrahend_xor[1]) | (minuend[1] & carry_out) | (subtrahend_xor[1] & carry_out);

                    sum_result[2] = minuend[2] ^ subtrahend_xor[2] ^ carry_out;
                    carry_out     = (minuend[2] & subtrahend_xor[2]) | (minuend[2] & carry_out) | (subtrahend_xor[2] & carry_out);

                    sum_result[3] = minuend[3] ^ subtrahend_xor[3] ^ carry_out;
                    // Final result: sum_result[3:0]

                    mux_out_stage2 <= { { (DW-4){1'b0} }, sum_result[3:0] };
                end else begin
                    case (sel_stage1)
                        2'd0: mux_out_stage2 <= din_stage1[0];
                        2'd1: mux_out_stage2 <= din_stage1[1];
                        2'd2: mux_out_stage2 <= din_stage1[2];
                        default: mux_out_stage2 <= {DW{1'b0}};
                    endcase
                end
                valid_stage2 <= 1'b1;
            end else begin
                mux_out_stage2 <= mux_out_stage2;
                valid_stage2   <= 1'b0;
            end
        end
    end

    // Stage 3: Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout      <= {DW{1'b0}};
            valid_out <= 1'b0;
        end else begin
            if (valid_stage2) begin
                dout      <= mux_out_stage2;
                valid_out <= 1'b1;
            end else begin
                dout      <= dout;
                valid_out <= 1'b0;
            end
        end
    end

endmodule