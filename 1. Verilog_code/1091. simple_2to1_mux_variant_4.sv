//SystemVerilog

module simple_2to1_mux (
    input  wire        aclk,
    input  wire        aresetn,
    // AXI-Stream slave interface
    input  wire [0:0]  s_axis_tdata0,
    input  wire [0:0]  s_axis_tdata1,
    input  wire        s_axis_tvalid,
    input  wire        s_axis_tready,
    input  wire        s_axis_tuser_sel,
    // AXI-Stream master interface
    output wire [0:0]  m_axis_tdata,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready
);
    reg [0:0]  mux_out_reg;
    reg        mux_out_valid_reg;

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            mux_out_reg       <= 1'b0;
            mux_out_valid_reg <= 1'b0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                if (s_axis_tuser_sel)
                    mux_out_reg <= s_axis_tdata1;
                else
                    mux_out_reg <= s_axis_tdata0;
                mux_out_valid_reg <= 1'b1;
            end else if (m_axis_tvalid && m_axis_tready) begin
                mux_out_valid_reg <= 1'b0;
            end
        end
    end

    assign m_axis_tdata  = mux_out_reg;
    assign m_axis_tvalid = mux_out_valid_reg;

endmodule

module karatsuba_mult8 (
    input  wire        aclk,
    input  wire        aresetn,
    // AXI-Stream slave interface
    input  wire [15:0] s_axis_tdata,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    // AXI-Stream master interface
    output wire [15:0] m_axis_tdata,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready
);
    reg         input_ready_reg;
    reg         output_valid_reg;
    reg [15:0]  product_reg;
    reg [7:0]   operand_a_reg;
    reg [7:0]   operand_b_reg;

    wire [7:0]  operand_a_wire, operand_b_wire;
    wire [15:0] product_wire;

    assign operand_a_wire = s_axis_tdata[15:8];
    assign operand_b_wire = s_axis_tdata[7:0];

    assign s_axis_tready = input_ready_reg;
    assign m_axis_tdata  = product_reg;
    assign m_axis_tvalid = output_valid_reg;

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            input_ready_reg  <= 1'b1;
            output_valid_reg <= 1'b0;
            product_reg      <= 16'b0;
            operand_a_reg    <= 8'b0;
            operand_b_reg    <= 8'b0;
        end else begin
            // Accept input when slave is ready and valid, and output is not valid
            if (input_ready_reg && s_axis_tvalid && !output_valid_reg) begin
                operand_a_reg    <= operand_a_wire;
                operand_b_reg    <= operand_b_wire;
                input_ready_reg  <= 1'b0;
                output_valid_reg <= 1'b1;
            end else if (output_valid_reg && m_axis_tready) begin
                output_valid_reg <= 1'b0;
                input_ready_reg  <= 1'b1;
            end
        end
    end

    karatsuba_mult8_core karatsuba_mult8_core_inst (
        .operand_a(operand_a_reg),
        .operand_b(operand_b_reg),
        .product  (product_wire)
    );

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn)
            product_reg <= 16'b0;
        else if (input_ready_reg && s_axis_tvalid && !output_valid_reg)
            product_reg <= product_wire;
    end

endmodule

module karatsuba_mult8_core (
    input  wire [7:0] operand_a,
    input  wire [7:0] operand_b,
    output wire [15:0] product
);
    wire [3:0] a_high, a_low, b_high, b_low;
    wire [7:0] z0, z2, z1;
    wire [4:0] sum_a, sum_b;
    wire [7:0] z1_temp;
    wire [15:0] product_internal;

    assign a_high = operand_a[7:4];
    assign a_low  = operand_a[3:0];
    assign b_high = operand_b[7:4];
    assign b_low  = operand_b[3:0];

    // Recursive calls
    karatsuba_mult4 karatsuba_mult4_low (
        .operand_a(a_low),
        .operand_b(b_low),
        .product(z0)
    );

    karatsuba_mult4 karatsuba_mult4_high (
        .operand_a(a_high),
        .operand_b(b_high),
        .product(z2)
    );

    assign sum_a = a_high + a_low;
    assign sum_b = b_high + b_low;

    karatsuba_mult5 karatsuba_mult5_middle (
        .operand_a(sum_a),
        .operand_b(sum_b),
        .product(z1_temp)
    );

    assign z1 = z1_temp - z2 - z0;

    assign product_internal = {z2,8'b0} + ({z1,4'b0}) + {8'b0, z0};
    assign product = product_internal;

endmodule

module karatsuba_mult4 (
    input  wire [3:0] operand_a,
    input  wire [3:0] operand_b,
    output wire [7:0] product
);
    wire [1:0] a_high, a_low, b_high, b_low;
    wire [3:0] z0, z2, z1;
    wire [2:0] sum_a, sum_b;
    wire [3:0] z1_temp;
    wire [7:0] product_internal;

    assign a_high = operand_a[3:2];
    assign a_low  = operand_a[1:0];
    assign b_high = operand_b[3:2];
    assign b_low  = operand_b[1:0];

    // Recursive calls
    karatsuba_mult2 karatsuba_mult2_low (
        .operand_a(a_low),
        .operand_b(b_low),
        .product(z0)
    );

    karatsuba_mult2 karatsuba_mult2_high (
        .operand_a(a_high),
        .operand_b(b_high),
        .product(z2)
    );

    assign sum_a = a_high + a_low;
    assign sum_b = b_high + b_low;

    karatsuba_mult3 karatsuba_mult3_middle (
        .operand_a(sum_a),
        .operand_b(sum_b),
        .product(z1_temp)
    );

    assign z1 = z1_temp - z2 - z0;

    assign product_internal = {z2,4'b0} + ({z1,2'b0}) + {4'b0, z0};
    assign product = product_internal;

endmodule

module karatsuba_mult5 (
    input  wire [4:0] operand_a,
    input  wire [4:0] operand_b,
    output wire [7:0] product
);
    assign product = operand_a * operand_b;
endmodule

module karatsuba_mult3 (
    input  wire [2:0] operand_a,
    input  wire [2:0] operand_b,
    output wire [3:0] product
);
    assign product = operand_a * operand_b;
endmodule

module karatsuba_mult2 (
    input  wire [1:0] operand_a,
    input  wire [1:0] operand_b,
    output wire [3:0] product
);
    assign product = operand_a * operand_b;
endmodule