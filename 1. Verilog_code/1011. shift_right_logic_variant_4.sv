//SystemVerilog
module shift_right_logic #(parameter WIDTH=8) (
    input clk,
    input rst_n,
    input [WIDTH-1:0] data_in,
    input [2:0] shift_amount,
    output reg [WIDTH-1:0] data_out
);

reg [WIDTH-1:0] data_in_reg;
reg [2:0] shift_amount_reg;
wire [WIDTH-1:0] shifted_data;

// 输入数据与移位量寄存
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_in_reg <= {WIDTH{1'b0}};
        shift_amount_reg <= 3'b0;
    end else if (rst_n && clk) begin
        data_in_reg <= data_in;
        shift_amount_reg <= shift_amount;
    end
end

assign shifted_data = data_in_reg >> shift_amount_reg;

// 输出数据寄存
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        data_out <= {WIDTH{1'b0}};
    else if (rst_n && clk)
        data_out <= shifted_data;
end

endmodule