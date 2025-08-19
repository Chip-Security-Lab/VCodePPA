//SystemVerilog
// SystemVerilog
// IEEE 1364-2005 Verilog标准
module s2p_shadow_reg #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire serial_in,
    input wire shift_en,
    input wire capture,
    output reg [WIDTH-1:0] shadow_out,
    output wire [WIDTH-1:0] parallel_out
);
    // Shift register for serial-to-parallel conversion
    reg [WIDTH-1:0] shift_reg;
    
    // Flattened always block for shift register and shadow register operations
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= {WIDTH{1'b0}};  // 使用参数化的复位值
            shadow_out <= {WIDTH{1'b0}}; // 使用参数化的复位值
        end
        else if (shift_en && capture) begin
            shift_reg <= {shift_reg[WIDTH-2:0], serial_in};
            shadow_out <= {shift_reg[WIDTH-2:0], serial_in};
        end
        else if (shift_en) begin
            shift_reg <= {shift_reg[WIDTH-2:0], serial_in};
        end
        else if (capture) begin
            shadow_out <= shift_reg;
        end
    end
    
    // Parallel output directly from shift register
    assign parallel_out = shift_reg;
    
endmodule