//SystemVerilog
module sync_buffer_async_rst (
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    input wire load,
    output wire [7:0] data_out
);
    reg [7:0] data_in_reg;
    reg load_reg;
    
    // Register inputs to improve timing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= 8'b0;
            load_reg <= 1'b0;
        end
        else begin
            data_in_reg <= data_in;
            load_reg <= load;
        end
    end
    
    // Output registers
    reg [7:0] data_out_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out_reg <= 8'b0;
        else if (load_reg)
            data_out_reg <= data_in_reg;
    end
    
    assign data_out = data_out_reg;
endmodule