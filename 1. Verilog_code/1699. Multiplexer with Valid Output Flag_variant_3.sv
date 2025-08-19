//SystemVerilog
// Selection logic submodule
module mux_selector #(
    parameter W = 32
)(
    input wire [W-1:0] in_data[0:3],
    input wire [1:0] select,
    input wire in_valid[0:3],
    output reg [W-1:0] selected_data,
    output reg selected_valid
);

    always @(*) begin
        selected_data = in_data[select];
        selected_valid = in_valid[select];
    end

endmodule

// Output register submodule
module mux_reg #(
    parameter W = 32
)(
    input wire clk,
    input wire rst_n,
    input wire [W-1:0] in_data,
    input wire in_valid,
    output reg [W-1:0] out_data,
    output reg out_valid
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_data <= {W{1'b0}};
            out_valid <= 1'b0;
        end else begin
            out_data <= in_data;
            out_valid <= in_valid;
        end
    end

endmodule

// Top-level module
module mux_with_valid #(
    parameter W = 32
)(
    input wire clk,
    input wire rst_n,
    input wire [W-1:0] in_data[0:3],
    input wire [1:0] select,
    input wire in_valid[0:3],
    output wire [W-1:0] out_data,
    output wire out_valid
);

    wire [W-1:0] selected_data;
    wire selected_valid;

    mux_selector #(.W(W)) u_selector (
        .in_data(in_data),
        .select(select),
        .in_valid(in_valid),
        .selected_data(selected_data),
        .selected_valid(selected_valid)
    );

    mux_reg #(.W(W)) u_reg (
        .clk(clk),
        .rst_n(rst_n),
        .in_data(selected_data),
        .in_valid(selected_valid),
        .out_data(out_data),
        .out_valid(out_valid)
    );

endmodule