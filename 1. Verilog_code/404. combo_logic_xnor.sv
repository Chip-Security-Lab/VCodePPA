module combo_logic_xnor (in_data1, in_data2, out_data);
    input wire in_data1, in_data2;
    output wire out_data;

    assign out_data = ~in_data1 & ~in_data2 | in_data1 & in_data2;
endmodule