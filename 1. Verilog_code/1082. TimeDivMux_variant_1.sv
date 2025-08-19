//SystemVerilog
module TimeDivMux #(parameter DW=8) (
    input clk, rst,
    input [3:0][DW-1:0] ch,
    output reg [DW-1:0] out
);
    reg [1:0] cnt;
    wire [1:0] cnt_next;
    reg [DW-1:0] ch_reg [3:0];
    reg [DW-1:0] mux_out;

    // 4-bit subtractor lookup table
    reg [3:0] lut_sub [0:15][0:15];

    integer i, j;

    // Initialize the subtraction lookup table
    initial begin
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                lut_sub[i][j] = i - j;
            end
        end
    end

    // Register inputs (forward retiming: move registers after logic)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ch_reg[0] <= {DW{1'b0}};
            ch_reg[1] <= {DW{1'b0}};
            ch_reg[2] <= {DW{1'b0}};
            ch_reg[3] <= {DW{1'b0}};
        end else begin
            ch_reg[0] <= ch[0];
            ch_reg[1] <= ch[1];
            ch_reg[2] <= ch[2];
            ch_reg[3] <= ch[3];
        end
    end

    // Counter logic
    always @(posedge clk or posedge rst) begin
        if (rst)
            cnt <= 2'b00;
        else
            cnt <= cnt_next;
    end

    // Use the LUT for subtraction: cnt_next = cnt + 1
    assign cnt_next = lut_sub[cnt][4'd15];

    // Mux output logic (using registered inputs)
    always @* begin
        mux_out = ch_reg[cnt];
    end

    // Register output
    always @(posedge clk or posedge rst) begin
        if (rst)
            out <= {DW{1'b0}};
        else
            out <= mux_out;
    end

endmodule