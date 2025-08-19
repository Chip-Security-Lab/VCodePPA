//SystemVerilog
module cond_ops (
    input [3:0] val,
    input sel,
    output [3:0] mux_out,
    output [3:0] invert
);
    wire [3:0] add_result;
    wire [3:0] sub_result;
    
    arithmetic_unit arith_unit (
        .val(val),
        .add_result(add_result),
        .sub_result(sub_result)
    );
    
    mux_selector mux_unit (
        .sel(sel),
        .add_in(add_result),
        .sub_in(sub_result),
        .mux_out(mux_out)
    );
    
    inversion_unit inv_unit (
        .val(val),
        .inverted(invert)
    );
endmodule

module arithmetic_unit (
    input [3:0] val,
    output [3:0] add_result,
    output [3:0] sub_result
);
    wire [3:0] add_operand = 4'd5;
    wire [3:0] sub_operand = 4'd3;
    
    // Brent-Kung adder implementation
    wire [3:0] add_p, add_g;
    wire [3:0] add_c;
    
    // Generate and Propagate
    assign add_p = val ^ add_operand;
    assign add_g = val & add_operand;
    
    // Carry computation
    assign add_c[0] = add_g[0];
    assign add_c[1] = add_g[1] | (add_p[1] & add_g[0]);
    assign add_c[2] = add_g[2] | (add_p[2] & add_g[1]) | (add_p[2] & add_p[1] & add_g[0]);
    assign add_c[3] = add_g[3] | (add_p[3] & add_g[2]) | (add_p[3] & add_p[2] & add_g[1]) | 
                     (add_p[3] & add_p[2] & add_p[1] & add_g[0]);
    
    // Sum computation
    assign add_result = add_p ^ {add_c[2:0], 1'b0};
    
    // Subtraction using Brent-Kung adder
    wire [3:0] sub_p, sub_g;
    wire [3:0] sub_c;
    
    // Generate and Propagate
    assign sub_p = val ^ ~sub_operand;
    assign sub_g = val & ~sub_operand;
    
    // Carry computation
    assign sub_c[0] = sub_g[0];
    assign sub_c[1] = sub_g[1] | (sub_p[1] & sub_g[0]);
    assign sub_c[2] = sub_g[2] | (sub_p[2] & sub_g[1]) | (sub_p[2] & sub_p[1] & sub_g[0]);
    assign sub_c[3] = sub_g[3] | (sub_p[3] & sub_g[2]) | (sub_p[3] & sub_p[2] & sub_g[1]) | 
                     (sub_p[3] & sub_p[2] & sub_p[1] & sub_g[0]);
    
    // Sum computation
    assign sub_result = sub_p ^ {sub_c[2:0], 1'b1};
endmodule

module mux_selector (
    input sel,
    input [3:0] add_in,
    input [3:0] sub_in,
    output [3:0] mux_out
);
    parameter ADD_SEL = 1'b1;
    reg [3:0] result;
    
    always @(*) begin
        result = (sel == ADD_SEL) ? add_in : sub_in;
    end
    
    assign mux_out = result;
endmodule

module inversion_unit (
    input [3:0] val,
    output [3:0] inverted
);
    reg [3:0] inv_reg;
    
    always @(*) begin
        inv_reg = ~val;
    end
    
    assign inverted = inv_reg;
endmodule