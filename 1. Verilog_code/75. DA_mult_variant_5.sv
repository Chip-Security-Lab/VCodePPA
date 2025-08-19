//SystemVerilog
module partial_product_gen (
    input clk,
    input rst_n,
    input valid_in,
    output ready_out,
    input [3:0] x,
    input [3:0] y,
    output valid_out,
    input ready_in,
    output [3:0] pp0,
    output [3:0] pp1,
    output [3:0] pp2,
    output [3:0] pp3
);

reg valid_out_reg;
reg [3:0] pp0_reg, pp1_reg, pp2_reg, pp3_reg;
reg [3:0] x_reg, y_reg;

assign ready_out = !valid_out_reg || ready_in;
assign valid_out = valid_out_reg;
assign pp0 = pp0_reg;
assign pp1 = pp1_reg;
assign pp2 = pp2_reg;
assign pp3 = pp3_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_out_reg <= 1'b0;
        pp0_reg <= 4'b0;
        pp1_reg <= 4'b0;
        pp2_reg <= 4'b0;
        pp3_reg <= 4'b0;
        x_reg <= 4'b0;
        y_reg <= 4'b0;
    end else begin
        if (valid_in && ready_out) begin
            x_reg <= x;
            y_reg <= y;
            valid_out_reg <= 1'b1;
        end else if (valid_out_reg && ready_in) begin
            valid_out_reg <= 1'b0;
        end
        
        if (valid_in && ready_out) begin
            pp0_reg <= y[0] ? x : 4'b0000;
            pp1_reg <= y[1] ? x : 4'b0000;
            pp2_reg <= y[2] ? x : 4'b0000;
            pp3_reg <= y[3] ? x : 4'b0000;
        end
    end
end

endmodule

module shift_adder (
    input clk,
    input rst_n,
    input valid_in,
    output ready_out,
    input [3:0] pp0,
    input [3:0] pp1,
    input [3:0] pp2,
    input [3:0] pp3,
    output valid_out,
    input ready_in,
    output [7:0] result
);

reg valid_out_reg;
reg [7:0] result_reg;
reg [3:0] pp0_reg, pp1_reg, pp2_reg, pp3_reg;

wire [7:0] shifted_pp1 = {pp1_reg, 1'b0};
wire [7:0] shifted_pp2 = {pp2_reg, 2'b00};
wire [7:0] shifted_pp3 = {pp3_reg, 3'b000};

assign ready_out = !valid_out_reg || ready_in;
assign valid_out = valid_out_reg;
assign result = result_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_out_reg <= 1'b0;
        result_reg <= 8'b0;
        pp0_reg <= 4'b0;
        pp1_reg <= 4'b0;
        pp2_reg <= 4'b0;
        pp3_reg <= 4'b0;
    end else begin
        if (valid_in && ready_out) begin
            pp0_reg <= pp0;
            pp1_reg <= pp1;
            pp2_reg <= pp2;
            pp3_reg <= pp3;
            valid_out_reg <= 1'b1;
        end else if (valid_out_reg && ready_in) begin
            valid_out_reg <= 1'b0;
        end
        
        if (valid_in && ready_out) begin
            result_reg <= {4'b0000, pp0} + shifted_pp1 + shifted_pp2 + shifted_pp3;
        end
    end
end

endmodule

module DA_mult (
    input clk,
    input rst_n,
    input valid_in,
    output ready_out,
    input [3:0] x,
    input [3:0] y,
    output valid_out,
    input ready_in,
    output [7:0] out
);

wire valid_pp, ready_pp;
wire [3:0] pp0, pp1, pp2, pp3;

partial_product_gen pp_gen (
    .clk(clk),
    .rst_n(rst_n),
    .valid_in(valid_in),
    .ready_out(ready_out),
    .x(x),
    .y(y),
    .valid_out(valid_pp),
    .ready_in(ready_pp),
    .pp0(pp0),
    .pp1(pp1),
    .pp2(pp2),
    .pp3(pp3)
);

shift_adder adder (
    .clk(clk),
    .rst_n(rst_n),
    .valid_in(valid_pp),
    .ready_out(ready_pp),
    .pp0(pp0),
    .pp1(pp1),
    .pp2(pp2),
    .pp3(pp3),
    .valid_out(valid_out),
    .ready_in(ready_in),
    .result(out)
);

endmodule