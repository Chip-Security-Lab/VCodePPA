//SystemVerilog
module parity_calc #(
    parameter WIDTH = 32
)(
    input [WIDTH-1:0] data,
    output parity
);
    assign parity = ^data;
endmodule

module parity_gen_param #(
    parameter WIDTH = 32
)(
    input en,
    input [WIDTH-1:0] data,
    output reg parity
);
    wire parity_temp;
    
    parity_calc #(
        .WIDTH(WIDTH)
    ) u_parity_calc (
        .data(data),
        .parity(parity_temp)
    );
    
    always @(*) begin
        if (en) begin
            parity = parity_temp;
        end else begin
            parity = 1'b0;
        end
    end
endmodule