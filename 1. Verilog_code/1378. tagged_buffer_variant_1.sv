//SystemVerilog
//IEEE 1364-2005 Verilog
module tagged_buffer (
    input wire clk,
    input wire [15:0] data_in,
    input wire [3:0] tag_in,
    input wire write_en,
    output reg [15:0] data_out,
    output reg [3:0] tag_out
);
    // Pre-registered input signals to reduce fanout and improve timing
    reg [15:0] data_in_reg;
    reg [3:0] tag_in_reg;
    reg write_en_reg;
    
    // Combined always block for both stages
    always @(posedge clk) begin
        // First stage: register the inputs
        data_in_reg <= data_in;
        tag_in_reg <= tag_in;
        write_en_reg <= write_en;
        
        // Second stage: conditionally update outputs
        if (write_en_reg) begin
            data_out <= data_in_reg;
            tag_out <= tag_in_reg;
        end
    end
endmodule