module cond_calc_xnor (ctrl, a, b, y);
    input ctrl;
    input a, b;
    output y;

    assign y = (ctrl) ? ~(a ^ b) : a | b;
endmodule