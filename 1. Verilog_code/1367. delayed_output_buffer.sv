module delayed_output_buffer (
    input wire clk,
    input wire [7:0] data_in,
    input wire load,
    output reg [7:0] data_out,
    output reg data_valid
);
    reg [7:0] buffer;
    reg valid_r;
    
    always @(posedge clk) begin
        if (load) begin
            buffer <= data_in;
            valid_r <= 1'b1;
        end else
            valid_r <= 1'b0;
        
        data_out <= buffer;
        data_valid <= valid_r;
    end
endmodule