//SystemVerilog
module TimeDivMux #(parameter DW=8) (
    input clk,
    input rst,
    input [3:0][DW-1:0] ch,
    output reg [DW-1:0] out
);
    // Pipeline Stage 1: Counter logic
    reg [1:0] cnt_stage1;
    reg [1:0] cnt_stage2;

    // Pipeline Stage 2: Channel select logic
    reg [DW-1:0] ch_sel_stage2;
    reg [DW-1:0] ch_sel_stage3;

    // Pipeline Stage 3: Output register
    reg [DW-1:0] out_stage3;

    // 2-bit incrementer function (optional, for clarity)
    function [1:0] inc_2bit;
        input [1:0] a;
        inc_2bit = a + 2'b01;
    endfunction

    // 4-bit subtractor using two's complement addition (not used, for completeness)
    function [1:0] sub_2bit;
        input [1:0] a, b;
        reg [1:0] b_inv;
        reg carry_in;
        begin
            b_inv = ~b;
            carry_in = 1'b1;
            sub_2bit = a + b_inv + carry_in;
        end
    endfunction

    // Stage 1: Counter pipeline register
    always @(posedge clk or posedge rst) begin
        if (rst)
            cnt_stage1 <= 2'b00;
        else
            cnt_stage1 <= inc_2bit(cnt_stage1);
    end

    // Stage 2: Pipeline register for counter and channel selection
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt_stage2 <= 2'b00;
            ch_sel_stage2 <= {DW{1'b0}};
        end else begin
            cnt_stage2 <= cnt_stage1;
            ch_sel_stage2 <= ch[cnt_stage1];
        end
    end

    // Stage 3: Pipeline register for channel selection
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ch_sel_stage3 <= {DW{1'b0}};
            out_stage3 <= {DW{1'b0}};
        end else begin
            ch_sel_stage3 <= ch_sel_stage2;
            out_stage3 <= ch_sel_stage2;
        end
    end

    // Output assignment
    always @(*) begin
        out = out_stage3;
    end

endmodule