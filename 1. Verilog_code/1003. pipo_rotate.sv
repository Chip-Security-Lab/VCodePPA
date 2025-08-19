module pipo_rotate #(
    parameter WIDTH = 16
)(
    input wire i_clk, i_rst, i_load, i_shift, i_dir,
    input wire [WIDTH-1:0] i_data,
    output reg [WIDTH-1:0] o_data
);
    always @(posedge i_clk) begin
        if (i_rst)
            o_data <= {WIDTH{1'b0}};
        else if (i_load)
            o_data <= i_data;
        else if (i_shift)
            o_data <= i_dir ? {o_data[WIDTH-2:0], o_data[WIDTH-1]} : {o_data[0], o_data[WIDTH-1:1]};
    end
endmodule