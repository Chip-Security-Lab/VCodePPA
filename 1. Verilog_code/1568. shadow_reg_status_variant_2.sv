//SystemVerilog
module shadow_reg_status #(parameter DW=8) (
    input clk, rst, en,
    input [DW-1:0] data_in,
    output reg [DW-1:0] data_out,
    output reg valid
);
    reg [DW-1:0] shadow_reg;
    
    // Shadow register update block - handles data capture
    always @(posedge clk) begin
        if (rst) begin
            shadow_reg <= {DW{1'b0}};
        end else if (en) begin
            shadow_reg <= data_in;
        end
    end
    
    // Output data register update block
    always @(posedge clk) begin
        if (rst) begin
            data_out <= {DW{1'b0}};
        end else if (!en) begin
            data_out <= shadow_reg;
        end
    end
    
    // Valid flag control block
    always @(posedge clk) begin
        if (rst) begin
            valid <= 1'b0;
        end else if (en) begin
            valid <= 1'b0;
        end else begin
            valid <= 1'b1;
        end
    end
endmodule