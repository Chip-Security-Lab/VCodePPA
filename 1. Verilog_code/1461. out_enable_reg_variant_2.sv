//SystemVerilog
module out_enable_reg(
    input clk, rst,
    input [15:0] data_in,
    input load, out_en,
    output reg [15:0] data_out
);
    reg [15:0] stored_data;
    reg out_en_reg;

    // Move register forward through combinatorial logic
    always @(posedge clk) begin
        if (rst) begin
            stored_data <= 16'h0;
            data_out <= 16'h0;
            out_en_reg <= 1'b0;
        end else begin
            if (load)
                stored_data <= data_in;
            
            out_en_reg <= out_en;
            data_out <= out_en_reg ? stored_data : 16'hZ;
        end
    end
endmodule