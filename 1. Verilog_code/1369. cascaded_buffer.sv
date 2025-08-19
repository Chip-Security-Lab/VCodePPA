module cascaded_buffer (
    input wire clk,
    input wire [7:0] data_in,
    input wire cascade_en,
    output wire [7:0] data_out
);
    reg [7:0] buffer1, buffer2, buffer3;
    
    always @(posedge clk) begin
        if (cascade_en) begin
            buffer1 <= data_in;
            buffer2 <= buffer1;
            buffer3 <= buffer2;
        end
    end
    
    assign data_out = buffer3;
endmodule