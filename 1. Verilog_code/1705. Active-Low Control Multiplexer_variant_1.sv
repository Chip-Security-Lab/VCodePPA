//SystemVerilog
module active_low_mux(
    input wire clk,
    input wire rst_n,
    input wire [23:0] src_a,
    input wire [23:0] src_b,
    input wire sel_n,
    input wire en_n,
    output reg [23:0] dest
);

    // Optimized single-stage implementation
    wire [23:0] mux_out;
    wire enable;
    
    // Combinational logic for selection and enable
    assign mux_out = sel_n ? src_b : src_a;
    assign enable = !en_n;
    
    // Single pipeline stage with optimized control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dest <= 24'h0;
        end else begin
            dest <= enable ? mux_out : 24'h0;
        end
    end

endmodule