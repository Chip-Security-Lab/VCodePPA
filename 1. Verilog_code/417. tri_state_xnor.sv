module tri_state_xnor (enable, a, b, z);
    input enable;
    input a, b;
    output z;

    wire nand_out, nor_out;

    nand n1 (nand_out, a, b);
    assign nor_out = ~a | ~b;

    assign z = enable ? ~(a ^ b) : 1'bz;
endmodule

