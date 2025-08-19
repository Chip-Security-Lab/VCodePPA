module tri_state_control(
    input wire enable,
    output wire tri_state_enable
);
    assign tri_state_enable = enable;
endmodule

module data_path(
    input wire data_in,
    output wire data_out_internal
);
    assign data_out_internal = data_in;
endmodule

module tri_state(
    input wire data_in,
    input wire enable,
    output wire data_out
);
    wire data_out_internal;
    wire tri_state_enable;
    
    data_path u_data_path(
        .data_in(data_in),
        .data_out_internal(data_out_internal)
    );
    
    tri_state_control u_control(
        .enable(enable),
        .tri_state_enable(tri_state_enable)
    );
    
    assign data_out = tri_state_enable ? data_out_internal : 1'bz;
endmodule