module dual_port_buffer (
    input wire clk,
    input wire [31:0] write_data,
    input wire write_en,
    input wire read_en,
    output reg [31:0] read_data
);
    reg [31:0] buffer;
    
    always @(posedge clk) begin
        if (write_en)
            buffer <= write_data;
        if (read_en)
            read_data <= buffer;
    end
endmodule