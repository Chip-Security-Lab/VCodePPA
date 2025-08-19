//SystemVerilog
module byte_enabled_buffer (
    input wire clk,
    input wire [31:0] data_in,
    input wire [3:0] byte_en,
    input wire write,
    output reg [31:0] data_out
);
    // Intermediate registers for data before the conditional logic
    reg [31:0] data_in_reg;
    reg [3:0] byte_en_reg;
    reg write_reg;
    
    // Combined always block with the same trigger condition (posedge clk)
    always @(posedge clk) begin
        // Register all inputs
        data_in_reg <= data_in;
        byte_en_reg <= byte_en;
        write_reg <= write;
        
        // Apply the logic with registered inputs
        if (write_reg) begin
            if (byte_en_reg[0]) data_out[7:0] <= data_in_reg[7:0];
            if (byte_en_reg[1]) data_out[15:8] <= data_in_reg[15:8];
            if (byte_en_reg[2]) data_out[23:16] <= data_in_reg[23:16];
            if (byte_en_reg[3]) data_out[31:24] <= data_in_reg[31:24];
        end
    end
endmodule