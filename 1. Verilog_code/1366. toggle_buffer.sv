module toggle_buffer (
    input wire clk,
    input wire toggle,
    input wire [15:0] data_in,
    input wire write_en,
    output wire [15:0] data_out
);
    reg [15:0] buffer_a, buffer_b;
    reg sel;
    
    always @(posedge clk) begin
        if (toggle)
            sel <= ~sel;
        
        if (write_en) begin
            if (sel)
                buffer_a <= data_in;
            else
                buffer_b <= data_in;
        end
    end
    
    assign data_out = sel ? buffer_b : buffer_a;
endmodule