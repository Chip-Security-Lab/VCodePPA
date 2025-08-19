//SystemVerilog
module cam_6 (
    input wire clk,
    input wire rst,
    input wire write_en,
    input wire [7:0] data_in,
    output reg match_flag
);
    reg [7:0] stored_bits;
    wire [7:0] xor_result;
    
    assign xor_result = stored_bits ^ data_in;
    
    always @(posedge clk) begin
        if (rst) begin
            stored_bits <= 8'b0;
            match_flag <= 1'b0;
        end else if (write_en) begin
            stored_bits <= data_in;
            match_flag <= 1'b0;
        end else begin
            match_flag <= ~(|xor_result);
        end
    end
endmodule