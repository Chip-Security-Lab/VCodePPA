//SystemVerilog
module sync_rst_buffer (
    input wire clk,
    input wire rst,
    input wire [31:0] data_in,
    input wire load,
    output reg [31:0] data_out
);
    // Register the inputs to reduce input to first register delay
    reg rst_reg;
    reg [31:0] data_in_reg;
    reg load_reg;
    
    // Input registration
    always @(posedge clk) begin
        rst_reg <= rst;
        data_in_reg <= data_in;
        load_reg <= load;
    end
    
    // Data output logic with registered inputs
    always @(posedge clk) begin
        if (rst_reg)
            data_out <= 32'b0;
        else if (load_reg)
            data_out <= data_in_reg;
    end
endmodule