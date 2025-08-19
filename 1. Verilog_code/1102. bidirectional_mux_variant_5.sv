//SystemVerilog
module bidirectional_mux (
    inout wire [7:0] port_a,
    inout wire [7:0] port_b,
    inout wire [7:0] common_port,
    input wire direction,
    input wire active
);

    reg [7:0] port_a_out;
    reg [7:0] port_b_out;
    reg [7:0] common_port_out;
    reg port_a_oe;
    reg port_b_oe;
    reg common_port_oe;

    // Port A output enable logic
    always @(*) begin
        if (active && !direction)
            port_a_oe = 1'b1;
        else
            port_a_oe = 1'b0;
    end

    // Port B output enable logic
    always @(*) begin
        if (active && direction)
            port_b_oe = 1'b1;
        else
            port_b_oe = 1'b0;
    end

    // Common port output enable logic
    always @(*) begin
        if (active)
            common_port_oe = 1'b1;
        else
            common_port_oe = 1'b0;
    end

    // Port A output value logic
    always @(*) begin
        if (active && !direction)
            port_a_out = common_port;
        else
            port_a_out = 8'b0;
    end

    // Port B output value logic
    always @(*) begin
        if (active && direction)
            port_b_out = common_port;
        else
            port_b_out = 8'b0;
    end

    // Common port output value logic
    always @(*) begin
        if (active) begin
            if (direction)
                common_port_out = port_a;
            else
                common_port_out = port_b;
        end else begin
            common_port_out = 8'b0;
        end
    end

    // Tristate buffer implementation for bidirectional ports
    assign port_a = port_a_oe ? port_a_out : 8'bz;
    assign port_b = port_b_oe ? port_b_out : 8'bz;
    assign common_port = common_port_oe ? common_port_out : 8'bz;

endmodule