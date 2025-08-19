//SystemVerilog
module param_d_latch #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] data_in,
    input wire enable,
    output reg [WIDTH-1:0] data_out
);

    // Internal registers for parallel prefix subtraction
    reg [WIDTH-1:0] data_reg;
    reg [WIDTH-1:0] prop;
    reg [WIDTH-1:0] gen;
    reg [WIDTH-1:0] carry;
    
    // Generate and propagate signals
    always @* begin
        if (enable) begin
            for (int i = 0; i < WIDTH; i++) begin
                prop[i] = data_in[i];
                gen[i] = ~data_in[i];
            end
        end
    end

    // Parallel prefix carry computation
    always @* begin
        if (enable) begin
            carry[0] = 1'b1;
            for (int i = 1; i < WIDTH; i++) begin
                carry[i] = gen[i-1] | (prop[i-1] & carry[i-1]);
            end
        end
    end

    // Final subtraction result
    always @* begin
        if (enable) begin
            for (int i = 0; i < WIDTH; i++) begin
                data_reg[i] = prop[i] ^ carry[i];
            end
        end
    end

    // Output stage
    always @* begin
        data_out = data_reg;
    end

endmodule