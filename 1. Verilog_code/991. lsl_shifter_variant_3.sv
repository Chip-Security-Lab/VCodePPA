//SystemVerilog
module lsl_shifter(
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire [7:0] data_in,
    input wire [2:0] shift_amt,
    output reg [7:0] data_out
);
    reg [7:0] data_in_reg;
    reg [2:0] shift_amt_reg;
    reg [7:0] shift_result;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= 8'b0;
            shift_amt_reg <= 3'b0;
        end else if (en) begin
            data_in_reg <= data_in;
            shift_amt_reg <= shift_amt;
        end
    end

    always @* begin
        case (shift_amt_reg)
            3'd0: shift_result = data_in_reg;
            3'd1: shift_result = {data_in_reg[6:0], 1'b0};
            3'd2: shift_result = {data_in_reg[5:0], 2'b00};
            3'd3: shift_result = {data_in_reg[4:0], 3'b000};
            3'd4: shift_result = {data_in_reg[3:0], 4'b0000};
            3'd5: shift_result = {data_in_reg[2:0], 5'b00000};
            3'd6: shift_result = {data_in_reg[1:0], 6'b000000};
            3'd7: shift_result = {data_in_reg[0], 7'b0000000};
            default: shift_result = 8'b0;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= 8'b0;
        else if (en)
            data_out <= shift_result;
    end
endmodule