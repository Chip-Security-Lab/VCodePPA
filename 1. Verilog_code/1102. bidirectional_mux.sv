module bidirectional_mux (
    inout wire [7:0] port_a, port_b, // Bidirectional ports
    inout wire [7:0] common_port, // Common port
    input wire direction,         // Data flow direction
    input wire active             // Active enable signal
);
    assign port_a = (active && !direction) ? common_port : 8'bz;
    assign port_b = (active && direction) ? common_port : 8'bz;
    assign common_port = active ? (direction ? port_a : port_b) : 8'bz;
endmodule