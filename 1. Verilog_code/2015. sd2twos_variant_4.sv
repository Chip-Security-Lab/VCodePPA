//SystemVerilog
module sd2twos #(
    parameter W = 8
)(
    input  wire             clk,
    input  wire             rst_n,
    input  wire [W-1:0]     sd,
    output wire [W:0]       twos
);

// Stage 1: Sign Extension
reg [W:0] sign_ext_stage;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        sign_ext_stage <= {W+1{1'b0}};
    else
        sign_ext_stage <= {sd[W-1], {W{1'b0}}};
end

// Stage 2: Align Input Data
reg [W:0] input_stage;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        input_stage <= {W+1{1'b0}};
    else
        input_stage <= {1'b0, sd};
end

// Stage 3: Addition (Main Data Path)
reg [W:0] sum_stage;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        sum_stage <= {W+1{1'b0}};
    else
        sum_stage <= input_stage + sign_ext_stage;
end

// Output Assignment
assign twos = sum_stage;

endmodule