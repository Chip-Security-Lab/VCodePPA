module mux_buffer (
    input wire clk,
    input wire [1:0] select,
    input wire [7:0] data_a, data_b, data_c, data_d,
    input wire write_en,
    output reg [7:0] data_out
);
    reg [7:0] buffers [0:3];
    
    always @(posedge clk) begin
        if (write_en) begin
            case (select)
                2'b00: buffers[0] <= data_a;
                2'b01: buffers[1] <= data_b;
                2'b10: buffers[2] <= data_c;
                2'b11: buffers[3] <= data_d;
            endcase
        end
        
        data_out <= buffers[select];
    end
endmodule
