module dataflow_adder(
    input clk,
    input rst_n,
    input [7:0] a,
    input [7:0] b,
    output reg [7:0] sum,
    output reg cout
);

// Input stage registers
reg [7:0] a_reg1, b_reg1;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        a_reg1 <= 8'd0;
        b_reg1 <= 8'd0;
    end else begin
        a_reg1 <= a;
        b_reg1 <= b;
    end
end

// Addition stage
reg [8:0] add_result;
wire [8:0] add_wire;
assign add_wire = a_reg1 + b_reg1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        add_result <= 9'd0;
    else
        add_result <= add_wire;
end

// Output stage
reg [7:0] sum_reg;
reg cout_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sum_reg <= 8'd0;
        cout_reg <= 1'b0;
    end else begin
        sum_reg <= add_result[7:0];
        cout_reg <= add_result[8];
    end
end

// Final output assignment
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sum <= 8'd0;
        cout <= 1'b0;
    end else begin
        sum <= sum_reg;
        cout <= cout_reg;
    end
end

endmodule