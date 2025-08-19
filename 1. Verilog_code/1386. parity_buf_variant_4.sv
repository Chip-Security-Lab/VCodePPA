//SystemVerilog
module parity_buf_top #(parameter DW=9) (
    input clk, en,
    input [DW-2:0] data_in,
    output [DW-1:0] data_out
);
    // Internal signals and registers
    wire parity_bit;
    reg [DW-2:0] data_reg;
    reg parity_reg;
    
    // Parity generator instance
    parity_generator #(
        .WIDTH(DW-1)
    ) parity_gen_inst (
        .data(data_in),
        .parity(parity_bit)
    );
    
    // Register the input data and parity bit
    always @(posedge clk) begin
        if(en) begin
            data_reg <= data_in;
            parity_reg <= parity_bit;
        end
    end
    
    // Output assignment
    assign data_out = {parity_reg, data_reg};
    
endmodule

// Parity bit generator module
module parity_generator #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data,
    output parity
);
    assign parity = ^data; // XOR reduction for parity calculation
endmodule

// Output register module (kept for compatibility but functionality moved to top)
module output_register #(
    parameter DW = 9
)(
    input clk,
    input en,
    input [DW-2:0] data_in,
    input parity_in,
    output [DW-1:0] data_out
);
    // Pass-through implementation - functionality moved to top module
    reg [DW-1:0] data_out_reg;
    
    always @(posedge clk) begin
        if(en) begin
            data_out_reg <= {parity_in, data_in};
        end
    end
    
    assign data_out = data_out_reg;
endmodule