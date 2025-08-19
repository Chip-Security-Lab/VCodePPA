//SystemVerilog
// Top-level module: sync_4input_mux
module sync_4input_mux (
    input wire clk,                // Clock input
    input wire [3:0] data_inputs,  // 4 single-bit inputs  
    input wire [1:0] addr,         // Address selection
    output reg mux_output          // Registered output
);

    reg mux_selected_data; // Internal signal for combinational mux output

    // Combinational logic: 4-to-1 MUX based on addr
    always @(*) begin
        case (addr)
            2'b00: mux_selected_data = data_inputs[0];
            2'b01: mux_selected_data = data_inputs[1];
            2'b10: mux_selected_data = data_inputs[2];
            2'b11: mux_selected_data = data_inputs[3];
            default: mux_selected_data = 1'b0;
        endcase
    end

    // Sequential logic: Register the selected mux output on clock edge
    always @(posedge clk) begin
        mux_output <= mux_selected_data;
    end

endmodule

// 4-bit Karatsuba multiplier module
module karatsuba_mult4 (
    input  wire [3:0] op_a,
    input  wire [3:0] op_b,
    output wire [7:0] product
);
    wire [1:0] a_high, a_low, b_high, b_low;
    wire [3:0] z0, z1, z2;
    wire [2:0] a_sum, b_sum;
    wire [3:0] z1_temp, z0_temp, z2_temp;
    wire [7:0] prod_z2, prod_z1, prod_z0;

    assign a_high = op_a[3:2];
    assign a_low  = op_a[1:0];
    assign b_high = op_b[3:2];
    assign b_low  = op_b[1:0];

    assign a_sum = a_high + a_low;
    assign b_sum = b_high + b_low;

    karatsuba_mult2 u_z0 (
        .op_a(a_low),
        .op_b(b_low),
        .product(z0)
    );

    karatsuba_mult2 u_z2 (
        .op_a(a_high),
        .op_b(b_high),
        .product(z2)
    );

    karatsuba_mult2 u_z1 (
        .op_a(a_sum[1:0]),
        .op_b(b_sum[1:0]),
        .product(z1_temp)
    );

    // z1 = (z1_temp - z2 - z0)
    assign z1 = z1_temp - z2 - z0;

    assign prod_z2 = {z2,4'b0};          // z2 << 4
    assign prod_z1 = {z1,2'b0};          // z1 << 2
    assign prod_z0 = {4'b0, z0};         // z0

    assign product = prod_z2 + prod_z1 + prod_z0;

endmodule

// 2-bit Karatsuba multiplier module (base case)
module karatsuba_mult2 (
    input  wire [1:0] op_a,
    input  wire [1:0] op_b,
    output wire [3:0] product
);
    wire [0:0] a_high, a_low, b_high, b_low;
    wire [1:0] z0, z1, z2;
    wire [1:0] a_sum, b_sum;
    wire [1:0] z1_temp;
    wire [3:0] prod_z2, prod_z1, prod_z0;

    assign a_high = op_a[1];
    assign a_low  = op_a[0];
    assign b_high = op_b[1];
    assign b_low  = op_b[0];

    assign a_sum = a_high + a_low;
    assign b_sum = b_high + b_low;

    // z0 = a_low * b_low
    assign z0 = a_low & b_low;

    // z2 = a_high * b_high
    assign z2 = a_high & b_high;

    // z1 = (a_low + a_high) * (b_low + b_high) - z2 - z0
    assign z1_temp = a_sum & b_sum;
    assign z1 = z1_temp - z2 - z0;

    assign prod_z2 = {z2,2'b00};         // z2 << 2
    assign prod_z1 = {z1,1'b0};          // z1 << 1
    assign prod_z0 = {2'b00, z0};        // z0

    assign product = prod_z2 + prod_z1 + prod_z0;

endmodule