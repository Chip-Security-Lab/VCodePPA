module test_mode_xnor (test_mode, a, b, y);
    input test_mode, a, b;
    output y;

    assign y = test_mode ? ~(a ^ b) : 1'b0;
endmodule