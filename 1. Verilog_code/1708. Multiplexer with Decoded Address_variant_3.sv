//SystemVerilog
module parallel_prefix_adder #(
    parameter WIDTH = 2
)(
    input [WIDTH-1:0] addr,
    output [WIDTH-1:0] addr_comp,
    output [WIDTH-1:0] addr_comp_plus1,
    output [WIDTH-1:0] addr_comp_plus2,
    output [WIDTH-1:0] addr_comp_plus3
);
    wire [WIDTH-1:0] p0, g0;
    wire [WIDTH-1:0] p1, g1;
    wire [WIDTH-1:0] p2, g2;
    wire [WIDTH-1:0] p3, g3;
    
    assign p0 = ~addr;
    assign g0 = 2'b00;
    
    assign p1 = p0;
    assign g1 = g0 | (p0 & 2'b01);
    
    assign p2 = p1;
    assign g2 = g1 | (p1 & 2'b10);
    
    assign p3 = p2;
    assign g3 = g2 | (p2 & 2'b11);
    
    assign addr_comp = g0;
    assign addr_comp_plus1 = g1;
    assign addr_comp_plus2 = g2;
    assign addr_comp_plus3 = g3;
endmodule

module data_selector #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] data_array [0:3],
    input [1:0] addr_comp,
    input [1:0] addr_comp_plus1,
    input [1:0] addr_comp_plus2,
    input [1:0] addr_comp_plus3,
    output reg [WIDTH-1:0] selected_data
);
    always @(*) begin
        selected_data = (addr_comp == 2'b00) ? data_array[0] :
                       (addr_comp_plus1 == 2'b01) ? data_array[1] :
                       (addr_comp_plus2 == 2'b10) ? data_array[2] :
                       (addr_comp_plus3 == 2'b11) ? data_array[3] :
                       {WIDTH{1'b0}};
    end
endmodule

module decoded_addr_mux #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] data_array [0:3],
    input [1:0] addr,
    output [WIDTH-1:0] selected_data
);
    wire [1:0] addr_comp;
    wire [1:0] addr_comp_plus1;
    wire [1:0] addr_comp_plus2;
    wire [1:0] addr_comp_plus3;
    
    parallel_prefix_adder #(
        .WIDTH(2)
    ) prefix_adder (
        .addr(addr),
        .addr_comp(addr_comp),
        .addr_comp_plus1(addr_comp_plus1),
        .addr_comp_plus2(addr_comp_plus2),
        .addr_comp_plus3(addr_comp_plus3)
    );
    
    data_selector #(
        .WIDTH(WIDTH)
    ) selector (
        .data_array(data_array),
        .addr_comp(addr_comp),
        .addr_comp_plus1(addr_comp_plus1),
        .addr_comp_plus2(addr_comp_plus2),
        .addr_comp_plus3(addr_comp_plus3),
        .selected_data(selected_data)
    );
endmodule